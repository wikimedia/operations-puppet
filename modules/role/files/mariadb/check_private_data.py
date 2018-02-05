#!/usr/bin/python3

import argparse
import csv
import os
import re
# requires python3-pymysql
import pymysql

# TODO:The following are hardcoded paths that will be parametrized
# location where operations/wmf-config repo is synced
mediawiki_config_path = '/usr/local/lib/mediawiki-config'
# location where private_tables from realm.pp is synced to a text file
private_tables_path = '/etc/mysql/private_tables.txt'
# location where cols.txt from redactraton is synced to a csv (db, table, col)
filtered_tables_path = '/etc/mysql/filtered_tables.txt'

# full path for all.dblist
all_dblist_path = os.path.join(mediawiki_config_path, 'dblists', 'all.dblist')
# full path for private.dblist
private_dblist_path = os.path.join(mediawiki_config_path, 'dblists',
                                   'private.dblist')
# full path for deleted.dblist
deleted_dblist_path = os.path.join(mediawiki_config_path, 'dblists',
                                   'deleted.dblist')

# ignore the following system or ops-created databases:
SYSTEM_DBS = ['mysql', 'information_schema', 'performance_schema', 'sys',
              'ops', 'percona']
# ignore the following user-created databases:
USER_DATABASES_REGEX = '^([su][0-9]+|p[0-9]+g[0-9]+)\_\_?'


def parse_db_file(path, format='txt'):
    """
    load files to memory arrays
    """
    content = []
    with open(path, 'r') as f:
        if format == 'txt':
            content = f.read().splitlines()
        elif format == 'csv':
            content = list(csv.reader(f))
    return content


def get_lists(all_dblist_path, private_dblist_path, deleted_dblist_path,
              filtered_tables_path):
    """
    convert data from files to arrays
    """
    all_dblist = parse_db_file(all_dblist_path)
    # we consider deleted wikis a private, too, for filtering purposes
    private_dblist = (parse_db_file(private_dblist_path)
                      + parse_db_file(deleted_dblist_path))
    private_tables = parse_db_file(private_tables_path)
    filtered_tables = parse_db_file(filtered_tables_path, 'csv')

    public_wiki_dbs = [db for db in all_dblist if db not in private_dblist]

    public_dbs = list(public_wiki_dbs)
    public_dbs.append('centralauth')
    public_dbs.append('heartbeat')
    public_view_dbs = [db + '_p' for db in public_dbs]

    # these 2 are public dbs, not wiki views
    public_dbs.append('information_schema_p')
    public_dbs.append('meta_p')
    return (private_dblist, private_tables, filtered_tables, public_wiki_dbs,
            public_view_dbs, public_dbs)


def get_private_databases(db, public_dbs, public_view_dbs, system_dbs,
                          user_databases_regex):
    """
    check no private databases are present
    """
    cursor = db.cursor()
    databases = []
    cursor.execute('SELECT schema_name FROM information_schema.schemata')
    result = cursor.fetchall()
    for row in result:
        databases.append(row[0])
    cursor.close()

    non_public_wikis_present = ([d for d in databases if d not in public_dbs
                                and d not in public_view_dbs
                                and d not in system_dbs
                                and not re.match(user_databases_regex, d)])
    return non_public_wikis_present


def get_private_tables(db, private_tables, system_dbs, user_databases_regex):
    """
    check no private tables are present
    """
    cursor = db.cursor()
    format_in_private_tables = ','.join(['%s'] * len(private_tables))
    format_in_system_dbs = ','.join(['%s'] * len(system_dbs))
    query = ("SELECT table_schema, table_name"
             " FROM information_schema.tables"
             " WHERE table_name IN ({})"
             " AND table_schema NOT RLIKE %s"
             " AND table_schema NOT IN ({})"
             ).format(format_in_private_tables, format_in_system_dbs)
    cursor.execute(query,
                   private_tables + [user_databases_regex] + system_dbs)
    result = cursor.fetchall()
    cursor.close()

    return result


def column_has_private_data(conn, database, table, column):
    """
    check that given column is not null or the empty string
    """
    cursor = conn.cursor()
    has_private_data = False
    try:
        query = ("SELECT count(*)"
                 " FROM `{}`.`{}`"
                 " WHERE IF(`{}` IS NULL, 0,"
                 "          TRIM(LEADING '\0' FROM `{}`) NOT IN ('0', ''))")
        query = query.format(database, table, column, column)
        cursor.execute(query)
        result = cursor.fetchall()
        if int(result[0][0]) > 0:
            has_private_data = True
            print('-- Found private data: {}.{} {}'.format(database, table,
                                                           column, column))
    # Ignore "table doesn't exist" errors
    except pymysql.err.ProgrammingError:
        pass
    # Ignore "field doesn't exist" errors
    except pymysql.err.InternalError:
        pass
    cursor.close()
    return has_private_data


def get_unfiltered_columns(conn, filtered_tables, public_wiki_dbs):
    """
    check no private fields are present
    """
    unfiltered_columns = []
    for line in filtered_tables:
        if line[2] == 'F':
            table = line[0]
            column = line[1]
            for database in public_wiki_dbs:
                if column_has_private_data(conn, database, table, column):
                    unfiltered_columns.append([database, table, column])
            for database in ['centralauth']:
                if column_has_private_data(conn, database, table, column):
                    unfiltered_columns.append([database, table, column])
    return unfiltered_columns


def drop_databases(dbs):
    """
    Prints an SQL drop database statement for each of the database given on
    the list
    """
    for db in dbs:
        print("DROP DATABASE IF EXISTS `{}`;".format(db))


def drop_tables(tables):
    """
    Prints a drop table statement for each of the database given on the list
    """
    for table in tables:
        print("DROP TABLE IF EXISTS `{}`.`{}`;".format(table[0], table[1]))


def update_columns(cols):
    """
    prints a commented update statement for each of the columns given
    on the list
    """
    for col in cols:
        print(("-- UPDATE `{}`.`{}`"
               "   SET `{}` = NULL;").format(col[0], col[1], col[2]))


def main(mysql_socket):
    (private_dblist, private_tables, filtered_tables, public_wiki_dbs,
     public_view_dbs, public_dbs) = get_lists(all_dblist_path,
                                              private_dblist_path,
                                              deleted_dblist_path,
                                              filtered_tables_path)
    db = pymysql.connect(host='localhost', user='root',
                         unix_socket=mysql_socket)

    print('-- Non-public databases that are present:')
    private_databases_present = get_private_databases(db, public_dbs,
                                                      public_view_dbs,
                                                      SYSTEM_DBS,
                                                      USER_DATABASES_REGEX)
    drop_databases(private_databases_present)

    print('-- Non-public tables that are present:')
    private_tables_present = get_private_tables(db, private_tables, SYSTEM_DBS,
                                                USER_DATABASES_REGEX)
    drop_tables(private_tables_present)

    print('-- Unfiltered columns that are present:')
    unfiltered_columns_present = get_unfiltered_columns(db, filtered_tables,
                                                        public_wiki_dbs)
    update_columns(unfiltered_columns_present)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-S', action='store', dest='mysql_socket',
                        default='/var/run/mysqld/mysqld.sock',
                        help='Set MySQL socket file')
    results = parser.parse_args()
    main(results.mysql_socket)
