#!/usr/bin/python
# requires python3-pymysql
import pymysql
import re
import csv

mediawiki_config_path = '/usr/local/lib/mediawiki-config/'
all_dblist_path = mediawiki_config_path + 'dblists/all.dblist'
private_dblist_path = mediawiki_config_path + 'dblists/private.dblist'
private_tables_path = '/etc/mysql/private_tables.txt'
filtered_tables_path = '/etc/mysql/filtered_tables.txt'

f = open(all_dblist_path, 'r')
all_dblist = f.read().splitlines()
f.close()

f = open(private_dblist_path, 'r')
private_dblist = f.read().splitlines()
f.close()

f = open(private_tables_path, 'r')
private_tables = f.read().splitlines()
f.close()

f = open(filtered_tables_path, 'r')
filtered_tables = list(csv.reader(f))
f.close()

public_wiki_dbs = [db for db in all_dblist if db not in private_dblist]
public_dbs = list(public_wiki_dbs)
public_dbs.append('centralauth')
public_dbs.append('heartbeat')
public_view_dbs = [db + '_p' for db in public_dbs]
system_dbs = ['mysql', 'information_schema', 'performance_schema', 'sys', 'ops', 'percona']
user_databases_regex = '^([su][0-9]+|p[0-9]+g[0-9]+)\_\_?'

db = pymysql.connect(host='localhost', user='root', unix_socket='/tmp/mysql.sock')

# check no private databases are present
cursor = db.cursor()
databases = []
cursor.execute('SELECT schema_name FROM information_schema.schemata')
result = cursor.fetchall()
for row in result:
    databases.append(row[0])
cursor.close()

regex = re.compile(user_databases_regex)
non_public_wikis_present = [db for db in databases if db not in public_dbs and db not in public_view_dbs and db not in system_dbs and not regex.match(db)]

print('Non-public, non user/system databases that are present:')
print(non_public_wikis_present)

# check no private tables are present
cursor = db.cursor()
format_strings = ','.join(['%s'] * len(private_tables))
query = 'SELECT table_schema, table_name FROM information_schema.tables WHERE table_name IN (%s)' % format_strings
query = query + " AND table_schema NOT RLIKE '%s'" % user_databases_regex
cursor.execute(query, private_tables)
result = cursor.fetchall()
cursor.close()

print('Non-public tables that are present:')
print(result)

# check no private fields are present

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
            except pymysql.err.ProgrammingError:
                pass
            except pymysql.err.InternalError:
                pass
            cursor.close()

print('Unfiltered columns that are present:')
print(unfiltered_columns)

