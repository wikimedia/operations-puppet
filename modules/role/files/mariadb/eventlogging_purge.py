from __future__ import print_function
from pprint import pprint

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


class Database(object):

    def __init__(self, db_host, db_port, db_name):
        self.db_name = db_name
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

    def get_all_tables(self):
        sql_query = (
            "SELECT table_name FROM information_schema.tables "
            "WHERE table_schema = '{}'".format(self.db_name)
        )
        cursor = self.connection.cursor()
        cursor.execute(sql_query)
        tables = [row[0] for row in cursor.fetchall()]
        cursor.close()
        return tables


class Terminator(object):

    def __init__(self, database, whitelist, newer_than, older_than):
        now = datetime.utcnow()
        relative_ts = lambda n: (now - timedelta(days=n)).strftime(DATE_FORMAT)
        self.database = database
        self.whitelist = whitelist
        self.start = relative_ts(newer_than)
        self.end = relative_ts(older_than)

    def purge(self, table):
        """
        table not in the whitelist ---> DELETE WHERE TS > 90 days (note: must be in batches, not all in once)
        - we can use DELETE TOP (1000) for example
        """
        pass

    def sanitize(self, table):
        """
        table in the whitelist:
        - SELECT * from table where TS > 90 and < 120 LIMIT X OFFSET 0... (iterative to batch)
        - retrieve all the table fields and the rows
        - foreach row, sanitize using the whitelist (either fields to NULL
          or fine grained approach for JSON)
        - UPDATE all the rows
        """
        pass


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
                               'following the allowed format (^[A-Za-z0-9_.]+$)'
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
    parser = argparse.ArgumentParser(description='EventLogging data retention script')
    parser.add_argument('dbhostname', help='The target db hostname to purge')
    parser.add_argument('--whitelist', default="whitelist.tsv",
                        help='The full path of the TSV whitelist file (default: whitelist.tsv)')
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
    args = parser.parse_args()

    # Logging setup
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
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
        terminator = Terminator(database, whitelist, args.newer_than, args.older_than)
        for table in tables:
            if table not in whitelist:
                terminator.purge(table)
            else:
                terminator.sanitize(table)

    except Exception as e:
        log.error(e)
        exit(1)
