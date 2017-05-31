#!/usr/bin/env python
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
   added to it (see COMMON_PERSISTENT_FIELDS). This ensures that important fields
   like timestamp or primary keys are preserved.
3) The script runs updates/deletes in batches to avoid blocking the database for too
   long creating contention with other write operations (like inserts).
"""

import argparse
import collections
import ConfigParser
import csv
import logging
import os
import re
import sys
import time
import unittest
import uuid

from datetime import datetime, timedelta
from mock import MagicMock, Mock, call, patch

import pymysql

DATE_FORMAT = '%Y%m%d%H%M%S'

# Fields that are always present due to the EventLogging Capsule.
# These ones are automatically whitelisted due to their importance.
COMMON_PERSISTENT_FIELDS = ('id', 'uuid', 'timestamp')

log = logging.getLogger(__name__)


class Database(object):

    def __init__(self, db_host, db_port, db_name, db_user, db_password):
        self.db_host = db_host
        self.db_name = db_name
        self.db_port = db_port

        self.connection = pymysql.connect(
            host=db_host,
            port=db_port,
            db=db_name,
            user=db_user,
            password=db_password,
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
            "host": self.db_host,
            "port": self.db_port,
            "database": self.db_name,
        }
        if dry_run:
            log.info("(DRY-RUN) Executing command: %s", command)
            result.update({
                "success": True,
                "fields": [],
                "rows": [],
                "numrows": 0,
            })
        else:
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
        command = (
            "SELECT table_name "
            "FROM information_schema.tables "
            "WHERE table_schema = %s"
        )
        result = self.execute(command, params=[self.db_name])
        if 'rows' not in result:
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

    def __init__(self, database, whitelist, newer_than, older_than,
                 batch_size, sleep_between_batches, dry_run=False):
        self.reference_time = datetime.utcnow()
        self.database = database
        self.whitelist = whitelist
        self.start = self.relative_ts(newer_than)
        self.end = self.relative_ts(older_than)
        self.batch_size = batch_size
        self.sleep_between_batches = sleep_between_batches
        self.dry_run = dry_run

    def relative_ts(self, days):
        return (self.reference_time - timedelta(days=days)).strftime(DATE_FORMAT)

    def purge(self, table):
        """
        Drop all the rows in a given table with timestamp between
        self.start and self.end.
        """
        command = (
            "DELETE FROM {} "
            "WHERE timestamp >= %(start_ts)s AND timestamp < %(end_ts)s "
            "LIMIT %(batch_size)s".format(table)
        )
        params = {
            'start_ts': self.start,
            'end_ts': self.end,
            'batch_size': self.batch_size,
        }
        result = self.database.execute(command, params, dry_run=self.dry_run)
        while result['numrows'] > 0:
            result = self.database.execute(command, params, dry_run=self.dry_run)
            time.sleep(self.sleep_between_batches)

    def _get_old_uuids(self, table, offset):
        """
        Return a list of uuids between self.start and self.end limiting
        the batch with a offset.
        """
        command = (
            "SELECT uuid from {} WHERE timestamp >= %(start_ts)s "
            "AND timestamp < %(end_ts)s LIMIT %(batch_size)s OFFSET %(offset)s"
            .format(table)
        )
        params = {
            'start_ts': self.start,
            'end_ts': self.end,
            'batch_size': self.batch_size,
            'offset': offset,
        }
        result = self.database.execute(command, params, self.dry_run)
        if result['rows']:
            return [x[0] for x in result['rows']]
        else:
            return []

    def sanitize(self, table):
        """
        Set all the fields not in the whitelist (for a given table) to NULL.
        """
        fields = self.database.get_table_fields(table)
        fields_to_keep = self.whitelist[table] + list(COMMON_PERSISTENT_FIELDS)
        fields_to_purge = filter(lambda f: f not in fields_to_keep, fields)
        values_string = ','.join([field + ' = NULL' for field in fields_to_purge])
        offset = 0
        uuids_current_batch = self._get_old_uuids(table, offset)
        command_template = (
            "UPDATE {0} "
            "SET {1} "
            "WHERE uuid IN ({{}})"
        ).format(table, values_string)

        while uuids_current_batch:
            uuids_no = len(uuids_current_batch)
            if uuids_no > self.batch_size:
                log.error("The number of uuids to sanitize {} is bigger "
                          "than the batch size {}, this condition should not "
                          "be possible, please review the code/data. "
                          .format(str(uuids_no), str(self.batch_size)))
                raise RuntimeError('Sanitization stopped as precautionary step.')

            uuids_current_batch_escaped = ["'" + x + "'" for x in uuids_current_batch]
            result = self.database.execute(
                command_template.format(",".join(uuids_current_batch_escaped)),
                dry_run=self.dry_run
            )
            if result['numrows'] < uuids_no:
                log.warn("The number of uuids to sanitize {} is bigger "
                         "than the number of updated rows in this batch {}. "
                         "Data already sanitized?"
                         .format(uuids_no, result['numrows']))
            elif result['numrows'] > uuids_no:
                log.error("The number of uuids to sanitize {} is lower "
                          "than the number of updated rows in this batch {}. "
                          "This is definitely an error in the code, please review it."
                          .format(uuids_no, result['numrows']))
                raise RuntimeError('Sanitization stopped as precautionary step.')

            if uuids_no < self.batch_size:
                # Avoid an extra SQL query to the database if the number of
                # uuids returned are less than BATCH_SIZE, since this value
                # means that we have already reached the last batch of uuids
                # to sanitize.
                uuids_current_batch = []
            else:
                offset += self.batch_size
                uuids_current_batch = self._get_old_uuids(table, offset)

            time.sleep(self.sleep_between_batches)


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


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='EventLogging data '
                                                 'retention script')
    parser.add_argument('--whitelist', default="whitelist.tsv",
                        help='The full path of the TSV whitelist file '
                             '(default: whitelist.tsv)')
    parser.add_argument('--dbport', default=3306, type=int,
                        help='The target db port (default: 3306)')
    parser.add_argument('--dbname', default='log',
                        help='The EventLogging database name (default: log)')
    parser.add_argument('--older-than', dest='older_than', default=90, type=int,
                        help='Delete logs older than this number of days'
                        ' (default: 90)')
    parser.add_argument('--newer-than', dest='newer_than', default=120, type=int,
                        help='Delete logs newer than this number of days'
                        ' (default: 91)')
    parser.add_argument('--dry-run', dest='dry_run', action='store_true',
                        help='Only print sql commands without executing them')
    parser.add_argument('--logfile', dest='logfile', default=None,
                        help='Redirect the script\'s output to a file rather '
                             'than stdout')
    parser.add_argument('--batch-size', dest='batch_size', default=1000, type=int,
                        help='Maximum number of DB rows to update/delete in one go.'
                             ' (default: 1000)')
    parser.add_argument('--sleep-between-batches', dest='sleep_between_batches',
                        default=1, type=int,
                        help='Sleep time in seconds between each delete/update batch.'
                             ' (default: 1)')
    parser.add_argument('--my-cnf', dest='my_cnf', default='/root/.my.cnf',
                        help='Path to the mysql configuration file. Requires '
                             'a [client] section containing user and password fields.'
                             'Default: /root/.my.cnf')
    args = parser.parse_args()

    log_format = ('%(levelname)s: line %(lineno)d: %(message)s')

    if args.logfile:
        logging.basicConfig(
            filename=args.logfile,
            level=logging.INFO,
            format=log_format
        )
    else:
        logging.basicConfig(
            stream=sys.stdout,
            level=logging.INFO,
            format=log_format
        )

    # Args basic checks
    if not os.path.exists(args.whitelist):
        log.error(
            "The whitelist filepath provided ({}) does not exist"
            .format(args.whitelist)
        )
        exit(1)

    if args.my_cnf and not os.path.exists(args.my_cnf):
        log.error(
            "The my_cnf filepath provided ({}) does not exist".format(args.my_cnf)
        )
        exit(1)

    if args.older_than < 90:
        log.error(
            "Attempt to delete data older than ({}) days "
            "(any value less than 90 is not supported)"
            .format(args.older_than)
        )
        exit(1)

    if args.newer_than <= args.older_than:
        log.error("--newer-than must be stricly greater than --older-than")
        exit(1)

    try:
        database = None

        # Parse whitelist file
        with open(args.whitelist, 'r') as whitelist_fd:
            lines = csv.reader(whitelist_fd, delimiter='\t')
            whitelist = parse_whitelist(lines)

        # Parse the db my.cnf config file

        config = ConfigParser.ConfigParser()
        config.read(args.my_cnf)
        db_user = config.get('client', 'user')
        db_password = config.get('client', 'password')

        # Connect to the database in localhost (no other option
        # available). This is a design choice to simplify auth
        # and to restrict the actions taken to the local db only.
        database = Database('localhost', int(args.dbport),
                            args.dbname, db_user, db_password)

        # Apply the retention policy to each table
        tables = database.get_all_tables()
        if not tables:
            log.info('Forcing close, no tables on the database.')
            exit(1)

        terminator = Terminator(
            database,
            whitelist,
            args.newer_than,
            args.older_than,
            args.batch_size,
            args.sleep_between_batches,
            dry_run=args.dry_run
        )
        # Two purging methods:
        # 1) if the table is not the in the whitelist it means that no field
        #    needs to be preserved, hence the rows can just be deleted.
        # 2) if the table is in the whitelist, the rows needs to be updated
        #    with all the fields not whitelisted set as NULL.
        for table in tables:
            if table not in whitelist:
                terminator.purge(table)
            else:
                terminator.sanitize(table)
    except Exception as e:
        log.exception("Exception while running main")
        exit(1)
    finally:
        if database:
            database.close_connection()


# ##### Tests ######
# To run:
#   python -m unittest eventlogging_cleaner
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
        print "Test: ", self._testMethodName

    @patch('pymysql.connect')
    def test_dry_run(self, mock):
        """
        Verify that the dry_run mode does not end up in any call
        to the database.
        """
        connection_mock = MagicMock()
        connection_mock.cursor.return_value = MagicMock()
        mock.return_value = connection_mock
        db = Database("localhost", 3306, "log", "batman", "NaNaNaNaNa")
        db.execute("show tables", dry_run=True)
        self.assertFalse(connection_mock.cursor.execute.called)


class TestParser(unittest.TestCase):

    def setUp(self):
        print "Test: ", self._testMethodName

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


class TestTerminator(unittest.TestCase):

    def setUp(self):
        print "Test: ", self._testMethodName
        self.database = MagicMock()
        self.batch_size = 1000
        self.terminator = Terminator(self.database, [], 120, 90,
                                     self.batch_size, 0.1, dry_run=False)

    def test_relative_ts(self):
        now = datetime.utcnow()
        self.terminator.reference_time = now
        result = self.terminator.relative_ts(30)
        expected_result = (now - timedelta(days=30)).strftime(DATE_FORMAT)
        self.assertEqual(result, expected_result)

    def test_purge(self):
        self.terminator.database.execute.side_effect = [{'numrows': self.batch_size},
                                                        {'numrows': self.batch_size},
                                                        {'numrows': 0}]

        expected_sql = (
            "DELETE FROM AwesomeTable WHERE timestamp >= %(start_ts)s "
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

    def test_get_old_uuids(self):
        random_uuids = [(str(uuid.uuid4()),) for r in xrange(self.batch_size)]
        self.terminator.database.execute.side_effect = [{'rows': random_uuids}]
        result = self.terminator._get_old_uuids("AwesomeTable", 10)
        expected_result = [x[0] for x in random_uuids]
        self.assertEqual(result, expected_result)

    def test_sanitize_one_batch(self):
        """
        Sanitize called on a number of uuids less or equal than one batch size
        """
        self.terminator.database.get_table_fields.return_value = ['id', 'uuid', 'field1',
                                                                  'field2', 'field3', 'field4']
        BATCH_SIZE_TEST = 400
        random_uuids = [(str(uuid.uuid4()),) for r in xrange(BATCH_SIZE_TEST)]
        self.terminator._get_old_uuids = Mock(return_value=random_uuids)
        self.terminator.database.execute.return_value = {'numrows': BATCH_SIZE_TEST}
        self.terminator.whitelist = {'AwesomeTable': ['field1', 'field2']}
        expected_fields_to_sanitize = ','.join(
            [field + ' = NULL' for field in ['field3', 'field4']]
        )
        expected_uuids_in_where = ','.join(["'" + x[0] + "'" for x in random_uuids])
        command_template = (
            "UPDATE AwesomeTable "
            "SET {0} "
            "WHERE uuid IN ({1})"
        ).format(expected_fields_to_sanitize, '{}')
        expected_command = command_template.format(expected_uuids_in_where)
        self.terminator.sanitize("AwesomeTable")
        self.terminator.database.execute.assert_has_calls([
            call(expected_command, dry_run=False),
        ])
        self.terminator.database.execute.assert_called_once()

    def test_sanitize_multi_batches(self):
        """
        Sanitize called on a number of uuids that requires multiple batches.
        This test ensure that the update statements are executed in the right
        order and in the right number.
        """
        self.terminator.database.get_table_fields.return_value = ['id', 'uuid', 'field1',
                                                                  'field2', 'field3', 'field4']
        random_uuids = [str(uuid.uuid4()) for r in xrange(self.batch_size)]
        random_uuids2 = [str(uuid.uuid4()) for r in xrange(5)]
        self.terminator._get_old_uuids = Mock(side_effect=[random_uuids, random_uuids2])
        self.terminator.database.execute.side_effect = [{'numrows': self.batch_size},
                                                        {'numrows': 5}]
        self.terminator.whitelist = {'AwesomeTable': ['field1', 'field2']}
        expected_fields_to_sanitize = ','.join(
            [field + ' = NULL' for field in ['field3', 'field4']]
        )
        expected_uuids_in_where_1 = ','.join(["'" + x[0] + "'" for x in random_uuids])
        expected_uuids_in_where_2 = ','.join(["'" + x[0] + "'" for x in random_uuids2])
        command_template = (
            "UPDATE AwesomeTable "
            "SET {0} "
            "WHERE uuid IN ({1})"
        ).format(expected_fields_to_sanitize, '{}')
        expected_command1 = command_template.format(expected_uuids_in_where_1)
        expected_command2 = command_template.format(expected_uuids_in_where_2)
        self.terminator.sanitize("AwesomeTable")
        self.terminator.database.execute.assert_has_calls([
            call(expected_command1, dry_run=False),
            call(expected_command2, dry_run=False),
        ])

    def test_sanitize_multi_batches_error_condition1(self):
        """
        The number of uuids returned for each batch should not be bigger
        than the batch size.
        """
        self.terminator.database.get_table_fields.return_value = ['id', 'uuid', 'field1',
                                                                  'field2', 'field3', 'field4']
        random_uuids = [str(uuid.uuid4()) for r in xrange(self.batch_size * 2)]
        self.terminator._get_old_uuids = Mock(side_effect=[random_uuids])
        self.terminator.database.execute.side_effect = [{'numrows': self.batch_size}]
        self.terminator.whitelist = {'AwesomeTable': ['field1', 'field2']}
        with self.assertRaisesRegexp(RuntimeError, 'Sanitization stopped as precautionary step.'):
            self.terminator.sanitize("AwesomeTable")
        self.assertEquals(self.terminator.database.execute.called, False)

    def test_sanitize_multi_batches_error_condition2(self):
        """
        The number of updated rows is bigger than the number of uuids in a batch.
        """
        self.terminator.database.get_table_fields.return_value = ['id', 'uuid', 'field1',
                                                                  'field2', 'field3', 'field4']
        random_uuids = [str(uuid.uuid4()) + "'" for r in xrange(self.batch_size)]
        self.terminator._get_old_uuids = Mock(side_effect=[random_uuids])
        self.terminator.database.execute.side_effect = [{'numrows': self.batch_size * 2}]
        self.terminator.whitelist = {'AwesomeTable': ['field1', 'field2']}
        with self.assertRaisesRegexp(RuntimeError, 'Sanitization stopped as precautionary step.'):
            self.terminator.sanitize("AwesomeTable")
