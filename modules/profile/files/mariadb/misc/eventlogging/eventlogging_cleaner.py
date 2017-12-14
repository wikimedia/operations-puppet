#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
This script enforces the Analytics data retention guidelines outlined in:
https://wikitech.wikimedia.org/wiki/Analytics/Systems/EventLogging/Data_retention_and_auto-purging

The script reads a whitelist (TSV file) with the following format for each line:

Tablename\tfield
Tablename\tfield2
Tablename2\tfield_bla
[...]

The script works in the following way: for each table in the EventLogging database,
it looks for any reference of it in the whitelist. If none is found, it means that
there is no interest of preserving any kind of non-sensitive data, therefore
the retention policy is applied simply deleting all the rows matching the time
delta provided in input. If one or more reference is found, it means that some
fields of a given table need to be preserved for historical analytics, therefore
the script will execute update commands to set to NULL all the non-whitelisted fields
belonging to rows matching the time delta provided in input.

Important notes:
1) The script is meant to run on the same host in which the database that needs
   to be cleaned is running. The script will try basic authentication
   if any of DB username/password are provided by the user as my.cnf configuration
   file (the conf file needs to have a [client] section with 'user' and 'password').
2) If a table is listed in the whitelist, then some of its fields are automatically
   added to it (see COMMON_PERSISTENT_FIELDS). This ensures that important non-sensitive
   fields like timestamp or primary keys are preserved.
3) The script runs updates/deletes in batches to avoid blocking the database for too
   long creating contention with other write operations (like inserts).
"""

import argparse
import collections
import configparser
import csv
import logging
import os
import pwd
import re
import sys
import time
import unittest

from datetime import datetime, timedelta
from unittest.mock import MagicMock, Mock, call, patch

import pymysql

DATE_FORMAT = '%Y%m%d%H%M%S'

# Fields that are always present due to the EventLogging Capsule.
# These ones are automatically whitelisted due to their importance.
COMMON_PERSISTENT_FIELDS = ('id', 'uuid', 'timestamp')

log = logging.getLogger(__name__)


class MaxLevelFilter(logging.Filter):

    def __init__(self, level):
        self.level = level

    def filter(self, record):
        return record.levelno < self.level


class Database(object):

    def __init__(self, db_host, db_name, db_user, db_password=None,
                 db_port=None, unix_socket=None):
        self.db_host = db_host
        self.db_name = db_name

        if (db_password is not None or db_port is not None) and unix_socket is not None:
            raise RuntimeError(
                "Can not create a database connection. Specify either db_port and db_password "
                "or unix_socket. You can not specify both at the same time."
            )

        self.connection = pymysql.connect(
            host=db_host,
            port=db_port,
            db=db_name,
            user=db_user,
            password=db_password,
            unix_socket=unix_socket,
            autocommit=True,
            charset='utf8',
            use_unicode=True,
        )

    def execute(self, command, params=None, dry_run=False):
        """
        Sends a single sql command to the server instance,
        returns metadata about the execution and the resulting data.
        """
        result = {
            "query": command,
            "args": params,
            "host": self.db_host,
            "database": self.db_name,
        }
        if dry_run:
            log.info(
                "(DRY-RUN) Executing command: %s with params: %s", command, params
            )
            result.update({
                "success": True,
                "fields": [],
                "rows": [],
                "numrows": 0,
            })
            return result

        try:
            with self.connection.cursor() as cursor:
                log.info("Executing command %s with params %s", command, params)
                cursor.execute(command, params)

                fields = None
                rows = None
                if cursor.rowcount > 0:
                    rows = cursor.fetchall()
                    fields = (
                        [] if not cursor.description
                        else [x[0] for x in cursor.description]
                    )
                numrows = cursor.rowcount

                result.update({
                    "success": True,
                    "fields": fields,
                    "rows": rows,
                    "numrows": numrows
                })

        except (pymysql.err.ProgrammingError, pymysql.err.OperationalError) as e:
            log.exception('An error as occurred while executing the SQL command')
            result.update({
                "success": False,
                "errno": e.args[0],
                "errmsg": e.args[1]
            })
        return result

    def get_all_tables(self):
        """
        Returns all the tables that holds EventLogging data.
        The log database may hold tables from other services like EventBus,
        so in this function we use a SQL query that checks for two attributes:
        timestamp and any event_*.
        """
        command = (
            "SELECT "
            "     table_name, "
            "     SUM(IF(column_name = 'timestamp', 1, 0)) AS has_timestamp_field, "
            "     SUM(IF(column_name LIKE 'event_%', 1, 0)) AS event_field_count "
            "FROM information_schema.columns "
            "WHERE table_schema = 'log' "
            "GROUP BY table_name "
            "HAVING "
            "has_timestamp_field = 1 AND "
            "event_field_count > 0"
        )
        result = self.execute(command)
        if 'rows' not in result or not result['rows']:
            log.error('No tables found in database ' + self.db_name)
            return []
        return [row[0] for row in result['rows']]

    def get_table_fields(self, table):
        command = "DESCRIBE {}".format(table)
        result = self.execute(command)
        return [row[0] for row in result['rows']]

    def close_connection(self):
        try:
            self.connection.close()
        except (pymysql.err.ProgrammingError,
                pymysql.err.OperationalError):
            log.exception("Failed to close the connection to the DB")


class Terminator(object):

    def __init__(self, database, whitelist, start_ts, end_ts,
                 batch_size, sleep_between_batches, dry_run=False):
        self.reference_time = datetime.utcnow()
        self.database = database
        self.whitelist = whitelist
        self.start = start_ts
        self.end = end_ts
        self.batch_size = batch_size
        self.sleep_between_batches = sleep_between_batches
        self.dry_run = dry_run

    def purge(self, table):
        """
        Drop all the rows in a given table with timestamp between
        self.start and self.end.
        """
        command = (
            "DELETE FROM `{}` "
            "WHERE timestamp >= %(start_ts)s AND timestamp < %(end_ts)s "
            "LIMIT %(batch_size)s".format(table)
        )
        params = {
            'start_ts': self.start,
            'end_ts': self.end,
            'batch_size': self.batch_size,
        }
        result = self.database.execute(command, params, dry_run=self.dry_run)
        # In case the deleted rows number is not equal to the batch size,
        # it means that we have completed the last batch so we can avoid
        # an extra loop cycle.
        while result['numrows'] == self.batch_size:
            result = self.database.execute(command, params, dry_run=self.dry_run)
            time.sleep(self.sleep_between_batches)

    def _get_last_ts(self, table, start_ts):
        """
        Return the timestamp of the Nth event between start_ts and self.end,
        where N is equal to the batch size. If there are less than N events
        between start_ts and self.end, return the timestamp of the last one.
        If there are no events between start_ts and self.end, return None.
        """
        if datetime.strptime(start_ts, DATE_FORMAT) > datetime.strptime(self.end, DATE_FORMAT):
            return None

        command = (
            "SELECT CAST(timestamp AS CHAR) from `{}` WHERE timestamp >= %(start_ts)s "
            "AND timestamp <= %(end_ts)s ORDER BY timestamp LIMIT %(batch_size)s, 1"
            .format(table)
        )
        params = {
            'start_ts': start_ts,
            'end_ts': self.end,
            'batch_size': self.batch_size - 1,
        }
        result = self.database.execute(command, params, self.dry_run)
        if result['rows']:
            return result['rows'][0][0]
        else:
            return self.end

    def _add_one_second(self, timestamp):
        dt = datetime.strptime(timestamp, DATE_FORMAT)
        dt1 = dt + timedelta(seconds=1)
        return dt1.strftime(DATE_FORMAT)

    def sanitize(self, table):
        """
        Set all the fields not in the whitelist (for a given table) to NULL.
        The schema_prefix is needed since the whitelist contains only EventLogging
        schema/table prefixes.
        """
        # Get the table's whitelist prefix to retrieve the list of fields to save
        # from the whitelist
        table_prefix = table.split('_')[0]
        # Sanity check
        if table_prefix not in self.whitelist:
            raise RuntimeError(
                "Sanitize has been called for table {}, but its "
                "prefix {} is not in the whitelist. Aborting as precautionary "
                "measure since this error condition might indicate a bug in the code"
                .format(table, table_prefix)
            )
        fields = self.database.get_table_fields(table)
        fields_to_keep = self.whitelist[table_prefix] + list(COMMON_PERSISTENT_FIELDS)
        fields_to_purge = [f for f in fields if f not in fields_to_keep]
        if not fields_to_purge:
            log.warning("No fields to purge for table {}.".format(table))
            return

        select_template = (
            "SELECT COUNT(*) FROM `{}` "
            "WHERE timestamp >= %(start_ts)s AND timestamp <= %(end_ts)s"
        ).format(table)
        values_string = ','.join(['`' + field + '` = NULL' for field in fields_to_purge])
        update_template = (
            "UPDATE `{}` "
            "SET {} "
            "WHERE timestamp >= %(start_ts)s AND timestamp <= %(end_ts)s"
        ).format(table, values_string)

        start_ts = self.start
        end_ts = self._get_last_ts(table, start_ts)
        while end_ts:
            # First, check if the start_ts-end_ts interval has an expected
            # number of events (<= 2 * batch_size), given that the end_ts
            # may contain a theoretically undefined number of events.
            # This corner case is unlikely to happen with the current
            # data stored in the EventLogging database, but it might be
            # generated by a future bug so it must be taken into account.
            # The solution is to simply use a safe threshold (2 * batch_size)
            # and abort the script in case it is breached; this should
            # prevent accidental huge UPDATE queries to the database
            # without overcomplicating the code.
            select_result = self.database.execute(
                select_template,
                {'start_ts': start_ts, 'end_ts': end_ts},
                dry_run=self.dry_run
            )
            if select_result['numrows'] > 2 * self.batch_size:
                log.error("The table {} has more than 2 * batch size events "
                          "between {} and {}. You may need to increase the "
                          "batch size or review the elements in the time"
                          "window."
                          .format(table, start_ts, end_ts))
                raise RuntimeError('Sanitization stopped as precautionary step.')

            # Batch size verified: sanitize the start_ts-end_ts interval.
            self.database.execute(
                update_template,
                {'start_ts': start_ts, 'end_ts': end_ts},
                dry_run=self.dry_run
            )

            # As end_ts is inclusive in the update statement
            # start next batch 1 second after end_ts
            # (Eventlogging's minimum timestamp granularity is 1s).
            start_ts = self._add_one_second(end_ts)
            end_ts = self._get_last_ts(table, start_ts)
            time.sleep(self.sleep_between_batches)


def check_not_valid_whitelist_table_prefixes(whitelist, tables):
    """
    Return all the whitelist table prefixes that do not match any table
    provided in input.
    """
    not_valid_table_prefixes = []
    for table_prefix in whitelist:
        if not [t for t in tables if t.startswith(table_prefix + '_')]:
            not_valid_table_prefixes.append(table_prefix)
    return not_valid_table_prefixes


def parse_whitelist(rows):
    """Parse rows containing tables and their attributes to whitelist

    Returns a hashmap with the following format:
    - each key is a table name
    - each value is a list of whitelisted fields
    {
        "tableName1": ["fieldName1", "fieldName2", ...],
        "tableName2": [...],
        ...
    }
    """
    whitelist_hash = collections.defaultdict(list)
    allowed_tablename_format = re.compile("^[A-Za-z0-9_]+$")
    allowed_fieldname_format = re.compile("^[A-Za-z0-9_.]+$")
    lineno = 0
    for lineno, row in enumerate(rows):
        if len(row) != 2:
            raise RuntimeError('Error in the whitelist, line {}: '
                               '2 elements per row allowed '
                               '(tab to separate them).'
                               .format(lineno))

        table_name = row[0].strip()
        field_name = row[1].strip()

        if not allowed_tablename_format.match(table_name):
            raise RuntimeError('Error in the whitelist, line {}: table name {} not '
                               'following the allowed format (^[A-Za-z0-9_]+$)'
                               .format(lineno, table_name))

        if not allowed_fieldname_format.match(field_name):
            raise RuntimeError('Error in the whitelist, line {}: field {} not '
                               'following the allowed format '
                               '(^[A-Za-z0-9_.]+$)'
                               .format(lineno, field_name))

        if field_name not in whitelist_hash[table_name]:
            whitelist_hash[table_name].append(field_name)
        else:
            raise RuntimeError('Error in the whitelist, line {}: field {} '
                               'is listed multiple times.'
                               .format(lineno, field_name))

    return whitelist_hash


def relative_ts(reference_time, days):
    return (reference_time - timedelta(days=days)).strftime(DATE_FORMAT)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='EventLogging data '
                                                 'retention script')
    parser.add_argument('--whitelist',
                        help='The full path of the TSV whitelist file. '
                             'Not compatible with --no-whitelist')
    parser.add_argument('--no-whitelist', action='store_true',
                        help='Bypass any whitelist and sanitization scheme. '
                             '(default: false).'
                             'Not compatible with --whitelist')
    parser.add_argument('--dbport', default=3306, type=int,
                        help='The target db port (default: 3306)')
    parser.add_argument('--dbname', default='log',
                        help='The EventLogging database name (default: log)')
    parser.add_argument('--older-than', dest='older_than', default=90, type=int,
                        help='Delete logs older than this number of days'
                        ' (default: 90)')
    parser.add_argument('--newer-than', dest='newer_than', type=int, default=0,
                        help='Delete logs newer than this number of days')
    parser.add_argument('--start-ts-file', dest='start_ts_file', default=None,
                        help="Ignore the --newer-than option and read the start timestamp "
                             "from the file path indicated as argument. This option is "
                             "useful when the script is used in cron, since any failure "
                             "could lead to sanitization gaps. The file is expected to "
                             "have a single line containing the start timestamp in the "
                             "format {}.".format(DATE_FORMAT.replace('%', '%%')))
    parser.add_argument('--dry-run', dest='dry_run', action='store_true',
                        help='Only print sql commands without executing them')
    parser.add_argument('--batch-size', dest='batch_size', default=1000, type=int,
                        help='Maximum number of DB rows to update/delete in one go.'
                             ' (default: 1000)')
    parser.add_argument('--sleep-between-batches', dest='sleep_between_batches',
                        default=1, type=int,
                        help='Sleep time in seconds between each delete/update batch.'
                             ' (default: 1)')
    parser.add_argument('--my-cnf', dest='my_cnf', default='/etc/my.cnf',
                        help='Path to the mysql configuration file. Requires '
                             'a [client] section containing user and unix_socket path '
                             'fields, or alternatively user and password (but the first '
                             'option is preferred). Default: /etc/my.cnf')
    args = parser.parse_args()

    log_format = logging.Formatter('%(levelname)s: line %(lineno)d: %(message)s')
    stdout_h = logging.StreamHandler(sys.stdout)
    stdout_h.addFilter(MaxLevelFilter(logging.WARNING))
    stdout_h.setFormatter(log_format)

    stderr_h = logging.StreamHandler(sys.stderr)
    stderr_h.setLevel(logging.ERROR)
    stderr_h.setFormatter(log_format)

    log.addHandler(stdout_h)
    log.addHandler(stderr_h)
    log.setLevel(logging.DEBUG)

    # Args basic checks
    if args.no_whitelist and args.whitelist:
        log.error(
            "The parameters --whitelist and --no-whitelist can't be used together."
        )
        sys.exit(1)

    if not (args.no_whitelist or args.whitelist):
        log.error(
            "One of --whitelist and --no-whitelist needs to be used."
        )
        sys.exit(1)

    if args.whitelist and not os.path.exists(args.whitelist):
        log.error(
            "The whitelist filepath provided ({}) does not exist"
            .format(args.whitelist)
        )
        sys.exit(1)

    if args.my_cnf and not os.path.exists(args.my_cnf):
        log.error(
            "The my_cnf filepath provided ({}) does not exist".format(args.my_cnf)
        )
        sys.exit(1)

    if args.newer_than > 0 and args.start_ts_file:
        log.error(
            "Only one between --newer-than and "
            "--start-ts-file can be specified."
        )
        sys.exit(1)

    if not (args.newer_than > 0 or args.start_ts_file):
        log.error(
            "One parameter between --newer-than and "
            "--start-ts-file is required."
        )
        sys.exit(1)

    if args.older_than < 90:
        log.error(
            "Attempt to delete data older than ({}) days "
            "(any value less than 90 is not supported)"
            .format(args.older_than)
        )
        sys.exit(1)

    try:
        database = None

        # Establish start/end timestamps from command line args
        now = datetime.utcnow()
        end_ts = relative_ts(now, args.older_than)

        if args.newer_than:
            start_ts = relative_ts(now, args.newer_than)
        elif args.start_ts_file:
            with open(args.start_ts_file, 'r') as filehandle:
                start_ts = filehandle.read().splitlines()[0]
                # Verify that the timestamp follows DATE_FORMAT
                datetime.strptime(start_ts, DATE_FORMAT)
        else:
            raise RuntimeError('Neither --newer-than nor --start-ts-file have been set.')

        if datetime.strptime(start_ts, DATE_FORMAT) > datetime.strptime(end_ts, DATE_FORMAT):
            log.error(
                "The start timestamp {} is more recent than the end timestamp {}, "
                "please review the input arguments.".format(start_ts, end_ts)
            )
            sys.exit(1)

        # Extra sanity check to make sure that no future changes to the args
        # parser will inadvertently cause data loss when deployed.
        assert(
            (args.whitelist and not args.no_whitelist)
            or (not args.whitelist and args.no_whitelist)
        )
        # Parse whitelist file
        if args.whitelist:
            with open(args.whitelist, 'r') as whitelist_fd:
                lines = csv.reader(whitelist_fd, delimiter='\t')
                whitelist = parse_whitelist(lines)
        else:
            whitelist = {}

        # Parse the db my.cnf config file
        # my.cn may contain duplicate entries within the same section
        # (like multiple plugin-load) and also empty statements (not followed by
        # by any '=') so configparser needs to be relaxed a bit to avoid
        # unnecessary runtime exceptions.
        config = configparser.ConfigParser(strict=False, allow_no_value=True)
        config.read(args.my_cnf)

        # Priority to the local unix socket, default to username/password
        try:
            unix_socket = config.get('client', 'socket')
            db_user = pwd.getpwuid(os.getuid())[0]
            db_password = None
            db_port = None
        except configparser.NoOptionError as e:
            log.info(
                "No local unix socket configured for myql, default to username/password"
            )
            unix_socket = None
            db_user = config.get('client', 'user')
            db_password = config.get('client', 'password')
            db_port = args.dbport

        # Connect to the database in localhost (no other option
        # available). This is a design choice to simplify auth
        # and to restrict the actions taken to the local db only.
        database = Database('localhost', args.dbname, db_user, db_password=db_password,
                            db_port=db_port, unix_socket=unix_socket)

        # Apply the retention policy to each table
        tables = database.get_all_tables()
        if not tables:
            log.info('Forcing close, no tables on the database.')
            sys.exit(1)

        # Sanity check
        bad_whitelist_entries = check_not_valid_whitelist_table_prefixes(whitelist, tables)
        if bad_whitelist_entries:
            log.error(
                "Some table prefixes in the whitelist do not match any "
                "table name retrieved from the database. Please review "
                "the following entries of the whitelist: %s", bad_whitelist_entries
            )
            sys.exit(1)

        terminator = Terminator(
            database,
            whitelist,
            start_ts,
            end_ts,
            args.batch_size,
            args.sleep_between_batches,
            dry_run=args.dry_run
        )

        # Assumption: the whitelist contains only table prefixes, not complete
        #             names. For example an EL table name could be 'Echo_1234_1234',
        #             and the correspondent whitelist entry would be 'Echo'.
        #
        # Two purging methods:
        # 1) if the table name does not match any table prefix contained
        #    in the whitelist, it means that no field
        #    needs to be preserved, hence the rows can just be deleted.
        # 2) if the table name matches any of the table prefixes contained
        #    in the whitelist, it means thta the rows needs to be updated
        #    with all the fields not whitelisted set as NULL.
        for table in tables:
            schema_prefix = table.split('_')[0]
            if schema_prefix not in whitelist:
                terminator.purge(table)
            else:
                terminator.sanitize(table)

        # The final step if args.start_ts_file is set is to replace
        # the timestamp in the file with end_ts. This is a very
        # basic form of commit, since if the next execution keeps using
        # args.start_ts_file then it will re-start from the last known good
        # sanitization checkpoint.
        if args.start_ts_file:
            with open(args.start_ts_file, 'w') as filehandle:
                log.info(
                    "Update {} with the current end_ts {}"
                    .format(args.start_ts_file, end_ts)
                )
                filehandle.write(end_ts)

    except Exception as e:
        log.exception("Exception while running main")
        sys.exit(1)
    finally:
        if database:
            database.close_connection()


# ##### Tests ######
# To run:
#   python3 -m unittest eventlogging_cleaner
#
# Why are the tests embedded in this file instead of a proper Python package?
#
# Deploying this script via puppet was considered to be a good tradeoff between
# the need of having tests and the effort to set up a proper code structure.
# The alternative was to create a proper Python package and deploy it via scap
# or via Debian package, but it was considered overkill.
#
# ###################


class TestDatabase(unittest.TestCase):

    def setUp(self):
        print("Test: ", self._testMethodName)

    @patch('pymysql.connect')
    def test_dry_run(self, mock):
        """
        Verify that the dry_run mode does not end up in any call
        to the database.
        """
        connection_mock = MagicMock()
        connection_mock.cursor.return_value = MagicMock()
        mock.return_value = connection_mock
        db = Database("localhost", "log", "batman", db_password="NaNaNaNaNa",
                      db_port=3306)
        db.execute("show tables", dry_run=True)
        self.assertFalse(connection_mock.cursor.execute.called)


class TestParser(unittest.TestCase):

    def setUp(self):
        print("Test: ", self._testMethodName)

    def test_check_not_valid_whitelist_table_prefixes(self):
        """
        Test if all the whitelist table prefixes not contained in the table
        list is returned correctly.
        """
        tables = ['AwesomeTableBatman_1234', 'AnotherTable_5677', 'AwesomeTable_789']
        whitelist = {'AwesomeTable': ['field1', 'field2'], 'NotGood': ['field1', 'field2']}
        expected_result = ['NotGood']
        result = check_not_valid_whitelist_table_prefixes(whitelist, tables)
        self.assertEqual(result, expected_result)

        tables = ['AwesomeTableBatman_1234', 'AnotherTable_5677', 'AwesomeTable_789']
        whitelist = {
            'AwesomeTable': ['field1', 'field2'],
            'AwesomeTableBatman': ['field1', 'field2']
        }
        result = check_not_valid_whitelist_table_prefixes(whitelist, tables)
        self.assertEqual(result, [])

    def test_row_elements(self):
        """
        Test basic functionality of the parser (for example the data
        structure returned must have a specific format and organization).
        """
        rows = [["TestTable", "TestField"]]
        result = parse_whitelist(rows)
        expected_result = {"TestTable": ["TestField"]}
        self.assertDictEqual(result, expected_result)

        rows = [["TestTable", "TestField"], ["TestTable", "TestField1"]]
        result = parse_whitelist(rows)
        expected_result = {"TestTable": ["TestField", "TestField1"]}
        self.assertDictEqual(result, expected_result)

        rows = [["TestTable_1", "TestField"],
                ["TestTable_1", "TestField2"],
                ["TestTable1", "TestField1.test"]]
        result = parse_whitelist(rows)
        expected_result = {
            "TestTable_1": ["TestField", "TestField2"],
            "TestTable1": ["TestField1.test"],
        }
        self.assertDictEqual(result, expected_result)

    def test_parse_guards(self):
        """
        Test basic input sanity checks to prevent easy mistakes
        while configuring the whitelist.
        """
        duplicate_rows = [["TestTable", "TestField"], ["TestTable", "TestField"]]
        with self.assertRaises(RuntimeError):
            parse_whitelist(duplicate_rows)

        wrong_chars_in_rows = [["TestTable.*", "TestField"], ["TestTable**", "TestField"]]
        with self.assertRaises(RuntimeError):
            parse_whitelist(wrong_chars_in_rows)

        wrong_chars_in_rows = [["TestTable", "TestField---"], ["TestTable", "TestField"]]
        with self.assertRaises(RuntimeError):
            parse_whitelist(wrong_chars_in_rows)

        too_many_el_in_rows = [["TestTable", "TestField", "NotRight"]]
        with self.assertRaises(RuntimeError):
            parse_whitelist(too_many_el_in_rows)


class TestTimestamps(unittest.TestCase):

    def test_relative_ts(self):
        now = datetime.utcnow()
        result = relative_ts(now, 30)
        expected_result = (now - timedelta(days=30)).strftime(DATE_FORMAT)
        self.assertEqual(result, expected_result)


class TestTerminator(unittest.TestCase):

    def setUp(self):
        print("Test: ", self._testMethodName)
        self.database = MagicMock()
        self.batch_size = 1000
        now = datetime.utcnow()
        start_ts = relative_ts(now, 120)
        end_ts = relative_ts(now, 90)
        self.terminator = Terminator(self.database, {}, start_ts, end_ts,
                                     self.batch_size, 0.1, dry_run=False)

    def test_purge(self):
        self.terminator.database.execute.side_effect = [{'numrows': self.batch_size},
                                                        {'numrows': self.batch_size},
                                                        {'numrows': 0}]

        expected_sql = (
            "DELETE FROM `AwesomeTable` WHERE timestamp >= %(start_ts)s "
            "AND timestamp < %(end_ts)s LIMIT %(batch_size)s"
        )
        expected_params = {
            'start_ts': self.terminator.start,
            'end_ts': self.terminator.end,
            'batch_size': self.terminator.batch_size,
        }
        self.terminator.purge("AwesomeTable")
        self.terminator.database.execute.assert_has_calls([
            call(expected_sql, expected_params, dry_run=False),
            call(expected_sql, expected_params, dry_run=False),
            call(expected_sql, expected_params, dry_run=False)
        ])

        # The Database execute method only catches pymysql specific exception,
        # returning a empty result. Any other exception returned is considered
        # not expected and the terminator class does not try to catch anything.
        self.terminator.database.execute.side_effect = RuntimeError("This is a bad exception")
        with self.assertRaises(RuntimeError):
            self.terminator.purge("AwesomeTable")

    def test_add_one_second(self):
        result = self.terminator._add_one_second('20170101000000')
        expected_result = '20170101000001'
        self.assertEqual(result, expected_result)

    def test_sanitize_one_batch(self):
        """
        Sanitize called on a time window containing less than batch size elements
        """
        self.terminator.database.get_table_fields.return_value = ['id', 'uuid', 'field1',
                                                                  'field2', 'field3', 'field4']
        self.terminator._get_last_ts = Mock(side_effect=[
            ('20170101000000'),
            None
        ])
        self.terminator.database.execute.return_value = {'numrows': 400}
        self.terminator.whitelist = {'AwesomeTable': ['field1', 'field2']}
        expected_fields_to_sanitize = ','.join(
            ['`' + field + '` = NULL' for field in ['field3', 'field4']]
        )

        expected_command1 = (
            "SELECT COUNT(*) FROM `AwesomeTable` WHERE timestamp >= %(start_ts)s "
            "AND timestamp <= %(end_ts)s"
        )

        expected_command2 = (
            "UPDATE `AwesomeTable` SET {} WHERE "
            "timestamp >= %(start_ts)s AND timestamp <= %(end_ts)s"
        ).format(expected_fields_to_sanitize)

        params = {
            'start_ts': self.terminator.start,
            'end_ts': '20170101000000',
        }

        self.terminator.sanitize("AwesomeTable")
        self.terminator.database.execute.assert_has_calls([
            call(expected_command1, params, dry_run=False),
            call(expected_command2, params, dry_run=False),
        ])

    def test_sanitize_multi_batches(self):
        """
        Sanitize called on a time window containing more than batch size elements,
        therefore requiring multiple UPDATE queries to the database.
        """
        self.terminator.database.get_table_fields.return_value = ['id', 'uuid', 'field1',
                                                                  'field2', 'field3', 'field4']
        self.terminator._get_last_ts = Mock(side_effect=[
            ('20170101000000'),
            ('20170101000010'),
            ('20170101000020'),
            None
        ])
        self.terminator.database.execute.return_value = {'numrows': 400}
        self.terminator.whitelist = {'AwesomeTable': ['field1', 'field2']}
        expected_fields_to_sanitize = ','.join(
            ['`' + field + '` = NULL' for field in ['field3', 'field4']]
        )

        expected_command1 = (
            "SELECT COUNT(*) FROM `AwesomeTable` WHERE timestamp >= %(start_ts)s "
            "AND timestamp <= %(end_ts)s"
        )
        expected_command2 = (
            "UPDATE `AwesomeTable` SET {} WHERE "
            "timestamp >= %(start_ts)s AND timestamp <= %(end_ts)s"
        ).format(expected_fields_to_sanitize)

        # The parameters are following a specific logic: the last end_ts
        # returned will not be used as the start_ts of the new batch to
        # avoid repetition of work. The function _add_one_second (tested above)
        # ensures that a second is added to each end_ts.
        params1 = {
            'start_ts': self.terminator.start,
            'end_ts': '20170101000000',
        }
        params2 = {
            'start_ts': '20170101000001',  # last end_ts + 1
            'end_ts': '20170101000010',
        }
        params3 = {
            'start_ts': '20170101000011',  # last end_ts + 1
            'end_ts': '20170101000020',
        }

        self.terminator.sanitize("AwesomeTable")
        self.terminator.database.execute.assert_has_calls([
            call(expected_command1, params1, dry_run=False),
            call(expected_command2, params1, dry_run=False),
            call(expected_command1, params2, dry_run=False),
            call(expected_command2, params2, dry_run=False),
            call(expected_command1, params3, dry_run=False),
            call(expected_command2, params3, dry_run=False),
        ])

    def test_sanitize_toobig_update_batch_error_condition(self):
        """
        Sanitize called on a time window containing more elements
        than the safe threshold of 2 * batch size. This corner case
        may happen for example if the end_ts of a batch is used by
        a lot of events due to a software bug or an unexpected event.
        In this case we don't want to hammer the database with a huge
        UPDATE query but fail gracefully.
        """
        self.terminator.database.get_table_fields.return_value = ['id', 'uuid', 'field1',
                                                                  'field2', 'field3', 'field4']
        self.terminator._get_last_ts = Mock(side_effect=[
            ('20170101000000'),
            ('20170101000010'),
            ('20170101000020'),
            None
        ])
        self.terminator.database.execute.side_effect = [
            {'numrows': self.terminator.batch_size},
            {'numrows': self.terminator.batch_size},
            {'numrows': 2 * self.terminator.batch_size + 1},
            {'numrows': 2 * self.terminator.batch_size + 1},
            {'numrows': self.terminator.batch_size},
            {'numrows': self.terminator.batch_size}
        ]

        self.terminator.whitelist = {'AwesomeTable': ['field1', 'field2']}
        expected_fields_to_sanitize = ','.join(
            ['`' + field + '` = NULL' for field in ['field3', 'field4']]
        )

        expected_command1 = (
            "SELECT COUNT(*) FROM `AwesomeTable` WHERE timestamp >= %(start_ts)s "
            "AND timestamp <= %(end_ts)s"
        )
        expected_command2 = (
            "UPDATE `AwesomeTable` SET {} WHERE "
            "timestamp >= %(start_ts)s AND timestamp <= %(end_ts)s"
        ).format(expected_fields_to_sanitize)

        params1 = {
            'start_ts': self.terminator.start,
            'end_ts': '20170101000000',
        }
        params2 = {
            'start_ts': '20170101000001',  # last end_ts + 1
            'end_ts': '20170101000010',
        }

        with self.assertRaises(RuntimeError):
            self.terminator.sanitize("AwesomeTable")
            self.terminator.database.assert_has_calls([
                call(expected_command1, params1, dry_run=False),
                call(expected_command2, params1, dry_run=False),
                call(expected_command1, params2, dry_run=False),
            ])

    def test_sanitize_table_without_fields_to_purge(self):
        """
        The table has all its fields white-listed or public by default.
        """
        self.terminator.database.get_table_fields.return_value = ['id', 'uuid', 'field1',
                                                                  'field2', 'field3', 'field4']
        self.terminator.whitelist = {'AwesomeTable': ['field1', 'field2', 'field3', 'field4']}
        self.terminator._get_last_ts = MagicMock()
        self.terminator.sanitize("AwesomeTable")
        self.assertFalse(self.terminator._get_last_ts.called)
