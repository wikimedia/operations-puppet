#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import datetime
import shutil
import sqlite3
import argparse
import os
from ldap3 import Server, Connection, ALL_ATTRIBUTES
from ldap3.core.exceptions import LDAPInvalidFilterError
from ldap3.utils.conv import escape_filter_chars

SERVER_URI = os.getenv('SERVER_URI', 'ldap://localhost:1389')
BASE_DN = 'ou=people,dc=wikimedia,dc=org'


def keep_backup(f):
    '''
    Keep a datetime stamped backup file
    '''

    d = datetime.datetime.utcnow()
    dst = '%s-%s' % (f, d.strftime('%Y%m%d%H%M'))
    shutil.copyfile(f, dst)


def connect_ldap():
    '''
    Connect to LDAP server and return a Connection object
    '''

    server = Server(SERVER_URI)
    conn = Connection(server)
    if conn.bind():
        return conn
    return None


def search_user(u, c):
    '''
    Using connection object c search for user u
    '''

    try:
        c.search(BASE_DN,
                 '(&(objectclass=person)(cn=%s))' % escape_filter_chars(u),
                 attributes=ALL_ATTRIBUTES)
    except LDAPInvalidFilterError:
        # Turns out ldap3 has a bug and can't handle parentheses in RHS
        # See https://github.com/cannatag/ldap3/pull/475
        return None
    if len(c.entries) > 1:
        raise RuntimeError('Search for user returned > 1 results: %s' % u)
    if len(c.entries) == 0:
        print('Warning: user does not exist in LDAP: %s' % u)
        return None
    return c.entries[0]


def migrate(infile, connection):
    '''
    Migrate the login attribute in SQLite to the LDAP populated one
    '''

    conn = sqlite3.connect(infile)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    cur.execute('''
    SELECT a.id, count(a.id) as C
    FROM user a
    JOIN user b
    ON a.login = lower(b.login)
    GROUP BY a.login
    HAVING C>1
    ORDER BY a.id
    ''')
    users = cur.fetchall()
    if len(users) > 0:
        for user in users:
            print('Duplicate user: %s' % user['id'])
        raise RuntimeError('Found duplicate users, bailing out')

    # No duplicates found, proceed
    cur.execute('SELECT * from user')
    users = cur.fetchall()
    stats = {
        'total': len(users),
        'migrated': 0,
    }
    for user in users:
        u = search_user(user['login'], connection)
        if u:
            try:
                cur.execute('UPDATE user set login=? where login=?',
                            (str(u.cn), user['login']))
                stats['migrated'] += 1
            except Exception as e:
                print('Failed to migrate user: %s, %s' %
                      (user['login'], e))
    conn.commit()
    return stats


def main():
    parser = argparse.ArgumentParser(
        description='Grafana SQLite migrator from proxy to LDAP auth')
    parser.add_argument('infile', help='input filename')
    args = parser.parse_args()

    # Keep a backup file
    keep_backup(args.infile)
    # Connect to LDAP
    connection = connect_ldap()
    stats = migrate(args.infile, connection)
    # Unbind
    connection.unbind()
    print('Total users: %s, migrated users: %s' %
          (stats['total'], stats['migrated']))


if __name__ == "__main__":
    main()
