#! /usr/bin/python3
# -*- coding: utf-8 -*-
"""
Automate and simplify maintenance of additional indexes on the wiki replicas
that are not present on the production databases.
"""

import argparse
import logging
import sys

import pymysql
import yaml


def dbs_with_table(cursor, table_name):
    """Return the names of the databases that include the table in question"""
    query = '''
    SELECT table_schema FROM information_schema.tables
    WHERE table_name='{table}' and table_schema
    like '%wik%' and table_type='BASE TABLE'
    '''.format(table=table_name)
    logging.debug(cursor.mogrify(query))
    cursor.execute(query)
    return [db[0] for db in cursor.fetchall()]


def check_index(cursor, db_name, index):
    """Check if the index exists, returning a boolean"""
    query = '''
    SELECT * FROM information_schema.statistics
    WHERE table_schema='{}' AND table_name='{}' AND
    index_name='{}'
    '''.format(db_name, index['table'], index['name'])
    logging.debug(cursor.mogrify(query))
    cursor.execute(query)
    return bool(cursor.rowcount)


def write_index(cursor, query, dryrun=False, debug=False):
    """Run the index statements after checking things"""
    if dryrun or debug:
        logging.info(cursor.mogrify(query))

    if not dryrun:
        cursor.execute(query)


def main():
    """Run the program"""
    # Parse the CLI
    parser = argparse.ArgumentParser(
        description='Creates and maintains indexes on a set of databases')
    parser.add_argument('-c', dest='config', metavar='<configuration_file>', type=str,
                        help='location of the configuration file (YAML)',
                        required=True)
    parser.add_argument(
        "--mysql-socket",
        help="Path to MySQL socket file",
        default="/run/mysqld/mysqld.sock"
    )
    parser.add_argument('--dryrun', dest='dryrun', action='store_true',
                        default=False, help='Print out SQL only')
    parser.add_argument('--debug', dest='debug', action='store_true',
                        default=False)
    args = parser.parse_args()

    logging.basicConfig(
        format='%(asctime)s %(levelname)s %(message)s',
        level=logging.DEBUG if args.debug else logging.INFO,
    )

    with open(args.config, 'r') as stream:
        try:
            config = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            logging.critical(exc)
            sys.exit(1)

    conn = pymysql.connect(
        user=config['mysql_user'],
        passwd=config['mysql_password'],
        unix_socket=args.mysql_socket,
        charset="utf8"
    )

    for index in config['indexes']:
        with conn.cursor() as cursor:
            cursor.execute("SET NAMES 'utf8';")
            cursor.execute("SET SESSION innodb_lock_wait_timeout=1;")
            cursor.execute("SET SESSION lock_wait_timeout=60;")
            dbs = dbs_with_table(cursor, index['table'])
            for db_name in dbs:
                query_string = '''
                ALTER TABLE {}.{} ADD KEY {} ({})
                '''.format(
                    db_name,
                    index['table'],
                    index['name'],
                    index['columns']
                )
                with conn.cursor() as change_cursor:
                    change_cursor.execute("SET NAMES 'utf8';")
                    change_cursor.execute("SET SESSION innodb_lock_wait_timeout=1;")
                    change_cursor.execute("SET SESSION lock_wait_timeout=60;")
                    if not check_index(change_cursor, db_name, index):
                        write_index(change_cursor, query_string, args.dryrun, args.debug)
                    else:
                        logging.debug('Skipping %s -- already exists', index['name'])


if __name__ == "__main__":
    main()
