from __future__ import print_function

import argparse
import collections
import csv
from datetime import datetime, timedelta
import logging
import os
import pymysql
import re
import sys


DATE_FORMAT = '%Y%m%d%H%M%S'
BATCH_SIZE = 1000
COMMON_PERSISTENT_FIELDS = ['id', 'timestamp']


# TODO: Think about having file handler!
logging.basicConfig(stream=sys.stdout, level=logging.INFO)


class Database(object):

    def __init__(self, db_host, db_port, db_name):
        self.db_host = db_host
        self.db_name = db_name
        self.db_port = db_port
        self.log = logging.getLogger(self.__class__.__name__)
        self.connection = pymysql.connect(
            host=db_host,
            port=db_port,
            db=db_name,
            user='root',
            password='root',
            autocommit=False,
            charset='utf8',
            use_unicode=True
        )

    def execute(self, command, dry_run=False):
        """
        Sends a single sql command to the server instance,
        returns metadata about the execution and the resulting data.
        """
        cursor = self.connection.cursor()
        result = {
            "query": command,
            "host": self.db_host,
            "port": self.db_port,
            "database": self.db_name
        }
        try:
            if dry_run:
                self.log.info((
                    "We will *NOT* execute \"{}\" on {}:{}/{} because "
                    "this is a dry run."
                ).format(command, self.db_host, self.db_port, self.db_name))
                result.update({
                    "success": True,
                    "fields": [],
                    "rows": [],
                    "numrows": 0
                })
                return result
            else:
                cursor.execute(command)
        except (pymysql.err.ProgrammingError,
                pymysql.err.OperationalError) as e:
            cursor.close()
            result.update({
                "success": False,
                "errno": e.args[0],
                "errmsg": e.args[1]
            })
            return result

        fields = None
        rows = None
        if cursor.rowcount > 0:
            rows = cursor.fetchall()
            fields = tuple([x[0] for x in cursor.description])
        numrows = cursor.rowcount
        cursor.close()

        result.update({
            "success": True,
            "fields": fields,
            "rows": rows,
            "numrows": numrows
        })
        return result

    def get_all_tables(self):
        command = (
            "SELECT table_name "
            "FROM information_schema.tables "
            "WHERE table_schema = '{}'"
        ).format(self.db_name)
        result = self.execute(command)
        return [row[0] for row in result['rows']]

    def get_table_fields(self, table):
        command = 'DESCRIBE {}'.format(table)
        result = self.execute(command)
        return [row[0] for row in result['rows']]


class Terminator(object):

    def __init__(self, database, whitelist, newer_than, older_than, dry_run):
        self.reference_time = datetime.utcnow()
        self.database = database
        self.whitelist = whitelist
        self.start = self.relative_ts(newer_than)
        self.end = self.relative_ts(older_than)
        self.dry_run = dry_run

    def relative_ts(self, days):
        return (self.reference_time - timedelta(days=days))\
            .strftime(DATE_FORMAT)

    def purge(self, table):
        """
        table not in the whitelist ---> DELETE WHERE TS > 90 days
        (note: must be in batches, not all in once)
        - we can use DELETE TOP (1000) for example

            start (newer_than 120 days)     end (older_than 90 days)    now
              |                              |                           |
        time------------------------------------------------------------>|
              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                    time range to purge
        """
        command = (
            "DELETE FROM {} "
            "WHERE timestamp >= '{}' AND timestamp < '{}' "
            "LIMIT {}"
        ).format(table, self.start, self.end, BATCH_SIZE)
        result = self.database.execute(command, self.dry_run)
        while result['numrows'] > 0:
            result = self.database.execute(command, self.dry_run)

    def sanitize(self, table):
        """
        table in the whitelist:
        - SELECT * from table where TS > 90 and < 120 LIMIT X OFFSET 0...
          (iterative to batch)
        - retrieve all the table fields and the rows
        - foreach row, sanitize using the whitelist (either fields to NULL
          or fine grained approach for JSON)
        - UPDATE all the rows
        """
        fields = self.database.get_table_fields(table)
        fields_to_keep = self.whitelist[table] + COMMON_PERSISTENT_FIELDS
        fields_to_purge = filter(lambda f: f not in fields_to_keep, fields)
        values_string = [field + ' = NULL' for field in fields_to_purge].join(', ')
        offset = 0
        command_template = (
            "UPDATE {0} "
            "SET {1} "
            "WHERE id IN ("
            "    SELECT id "
            "    FROM {0} "
            "    WHERE timestamp >= '{2}' AND timestamp < '{3}' "
            "    LIMIT {4} OFFSET {5}"
            ")"
        ).format(table, values_string, self.start, self.end, BATCH_SIZE, '{}')
        result = self.database.execute(command_template.format(offset))
        while result.numrows > 0:
            offset += BATCH_SIZE
            result = self.database.execute(command_template.format(offset))


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
    for row in rows:
        if len(row) != 2:
            raise RuntimeError('Error in the whitelist: '
                               'only 2 elements per row allowed.')

        table_name = row[0].strip()
        field_name = row[1].strip()

        if not allowed_tablename_format.match(table_name):
            raise RuntimeError('Error in the whitelist: table name {} not '
                               'following the allowed format (^[A-Za-z0-9_]+$)'
                               .format(table_name))

        if not allowed_fieldname_format.match(field_name):
            raise RuntimeError('Error in the whitelist: field {} not '
                               'following the allowed format '
                               '(^[A-Za-z0-9_.]+$)'
                               .format(field_name))

        if field_name not in whitelist_hash[table_name]:
            whitelist_hash[table_name].append(field_name)
        else:
            raise RuntimeError('Error in the whitelist: field {} '
                               'is listed multiple times.'
                               .format(field_name))

    return whitelist_hash


if __name__ == '__main__':
    # Define argument parser
    parser = argparse.ArgumentParser(description='EventLogging data '
                                                 'retention script')
    parser.add_argument('dbhostname', help='The target db hostname to purge')
    parser.add_argument('--whitelist', default="whitelist.tsv",
                        help='The full path of the TSV whitelist file '
                             '(default: whitelist.tsv)')
    parser.add_argument('--dbport', default=3306,
                        help='The target db port (default: 3306)')
    parser.add_argument('--dbname', default='log',
                        help='The EventLogging database name (default: log)')
    parser.add_argument('--older-than', dest='older_than', default=90,
                        help='Delete logs older than this number of days'
                        ' (default: 90)')
    parser.add_argument('--newer-than', dest='newer_than', default=120,
                        help='Delete logs newer than this number of days'
                        ' (default: 91)')
    parser.add_argument('--dry-run', dest='dry_run', action='store_true',
                        help='Only print sql commands without executing them')
    args = parser.parse_args()

    log = logging.getLogger('main')

    # Args basic checks
    if not os.path.exists(args.whitelist):
        log.error('The whitelist filepath provided does not exist')
        exit(1)

    try:
        # Parse whitelist file
        with open(args.whitelist, 'r') as whitelist_fd:
            lines = csv.reader(whitelist_fd, delimiter='\t')
            whitelist = parse_whitelist(lines)

        # Connect to the database
        # TODO: consider to use the following code
        # https://gerrit.wikimedia.org/r/#/c/338809/4/modules/role/files/mariadb/WMFMariaDB.py
        database = Database(args.dbhostname, int(args.dbport), args.dbname)

        # Apply the retention policy to each table
        tables = database.get_all_tables()
        terminator = Terminator(
            database,
            whitelist,
            args.newer_than,
            args.older_than,
            args.dry_run
        )
        for table in tables:
            if table not in whitelist:
                terminator.purge(table)
            else:
                terminator.sanitize(table)

    except Exception as e:
        log.error(e)
        exit(1)
