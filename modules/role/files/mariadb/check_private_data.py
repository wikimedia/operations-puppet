#!/usr/bin/python3

# requires python3-pymysql
import pymysql
import re
import csv

# location where operations/wmf-config repo is synced
mediawiki_config_path = '/usr/local/lib/mediawiki-config/'
# full path for all.dblist
all_dblist_path = mediawiki_config_path + 'dblists/all.dblist'
# full path for private.dblist
private_dblist_path = mediawiki_config_path + 'dblists/private.dblist'
# full path for deleted.dblist
deleted_dblist_path = mediawiki_config_path + 'dblists/deleted.dblist'
# location where private_tables from realm.pp is synced to a text file
private_tables_path = '/etc/mysql/private_tables.txt'
# location where cols.txt from redactraton is synced to a csv file (db, table, col)
filtered_tables_path = '/etc/mysql/filtered_tables.txt'

# ignore the following system or ops-created databases:
system_dbs = ['mysql', 'information_schema', 'performance_schema', 'sys', 'ops', 'percona']
# ignore the following user-created databases:
user_databases_regex = '^([su][0-9]+|p[0-9]+g[0-9]+)\_\_?'


# load files to memory arrays
def parse_file(path, format='txt'):
    content = []
    f = open(path, 'r')
    if format == 'txt':
        content = f.read().splitlines()
    elif format == 'csv':
        content = list(csv.reader(f))
    f.close()
    return(content)


# convert data to arrays
def get_lists(all_dblist_path, private_dblist_path, deleted_dblist_path, filtered_tables_path):
    all_dblist = parse_file(all_dblist_path)
    # we consider deleted wikis a private, too, for filtering purposes
    private_dblist = parse_file(private_dblist_path) + parse_file(deleted_dblist_path)
    private_tables = parse_file(private_tables_path)
    filtered_tables = parse_file(filtered_tables_path, 'csv')

    public_wiki_dbs = [db for db in all_dblist if db not in private_dblist]

    public_dbs = list(public_wiki_dbs)
    public_dbs.append('centralauth')
    public_dbs.append('heartbeat')
    public_view_dbs = [db + '_p' for db in public_dbs]

    # these 2 are public dbs, not wiki views
    public_dbs.append('information_schema_p')
    public_dbs.append('meta_p')
    return((private_dblist, private_tables, filtered_tables, public_wiki_dbs, public_view_dbs, public_dbs))


# check no private databases are present
def get_private_databases(db, public_dbs, public_view_dbs, system_dbs, user_databases_regex):
    cursor = db.cursor()
    databases = []
    cursor.execute('SELECT schema_name FROM information_schema.schemata')
    result = cursor.fetchall()
    for row in result:
        databases.append(row[0])
    cursor.close()

    regex = re.compile(user_databases_regex)
    non_public_wikis_present = [db for db in databases if db not in public_dbs and db not in public_view_dbs and db not in system_dbs and not regex.match(db)]

    return(non_public_wikis_present)


# check no private tables are present
def get_private_tables(db, private_tables, system_dbs, user_databases_regex):
    cursor = db.cursor()
    format_strings = ','.join(['%s'] * len(private_tables))
    query = 'SELECT table_schema, table_name FROM information_schema.tables WHERE table_name IN (%s)' % format_strings
    query = query + " AND table_schema NOT RLIKE '%s'" % user_databases_regex
    format_strings = ','.join(['%s'] * len(system_dbs))
    query = query + ' AND table_schema NOT IN (%s)' % format_strings
    cursor.execute(query, private_tables + system_dbs)
    result = cursor.fetchall()
    cursor.close()

    return(result)


# check no private fields are present
def get_unfiltered_columns(db, filtered_tables, public_wiki_dbs):
    unfiltered_columns = []
    for line in filtered_tables:
        if line[2] == 'F':
            table = line[0]
            column = line[1]
            for database in public_wiki_dbs:
                cursor = db.cursor()
                try:
                    query = "SELECT count(*) FROM `%s`.`%s` WHERE NOT (`%s` IS NOT NULL OR `%s` <> '')" % (database, table, column, column)
                    cursor.execute(query)
                    result = cursor.fetchall()
                    if int(result[0][0]) > 0:
                        unfiltered_columns.append([database, table, column])
                # Ignore "table doesn't exist" errors
                except pymysql.err.ProgrammingError:
                    pass
                # Ignore "field doesn't exist" errors
                except pymysql.err.InternalError:
                    pass
                cursor.close()

    return(unfiltered_columns)


def main():
    (private_dblist, private_tables, filtered_tables, public_wiki_dbs, public_view_dbs, public_dbs) = get_lists(all_dblist_path, private_dblist_path, deleted_dblist_path, filtered_tables_path)
    db = pymysql.connect(host='localhost', user='root', unix_socket='/tmp/mysql.sock')

    print('Non-public databases that are present:')
    private_databases_present = get_private_databases(db, public_dbs, public_view_dbs, system_dbs, user_databases_regex)
    print(private_databases_present)

    print('Non-public tables that are present:')
    private_tables_present = get_private_tables(db, private_tables, system_dbs, user_databases_regex)
    print(private_tables_present)
    print('Unfiltered columns that are present:')
    unfiltered_columns_present = get_unfiltered_columns(db, filtered_tables, public_wiki_dbs)
    print(unfiltered_columns_present)
    return(0)

if __name__ == "__main__":
    main()
