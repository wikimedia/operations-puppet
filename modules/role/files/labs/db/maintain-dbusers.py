#!/usr/bin/python3
"""
Has the following commands:

## harvest_cnf_files ##

 - Look through NFS for replica.my.cnf files
 - For those found, but no entry in `accounts` table, make an entry
 - For those found, and entry matches what was found, ignore

## harvest_dbaccounts ##
 - Look through all accounts in account db
 - Look through all users in all provisioned labsdbs
 - Make entries in account_host for all the users that match

This is meant to be used only in the beginning, to bootstrap the process.
When this is run, the state on the db is in sync with state on the NFS filesystem.

## sync-accounts ##

 - Construct list of tools / users from LDAP
 - Find new users and tools by comparing against data in DB
 - Create new mysql user accounts + grant them access, for all labsdb hosts

This shall be run in a cron or somesuch.
"""
import ldap3
import logging
import argparse
import yaml
import configparser
import os
import pymysql
from hashlib import sha1

PROJECT = 'tools'
ACCOUNT_CREATION_SQL = {
    'role': """
        GRANT USAGE ON *.* TO '{username}'@'%' IDENTIFIED BY '{password_hash}' WITH MAX_USER_CONNECTIONS {max_connections};
        GRANT labsdbuser TO '{username}'@'%';
        SET DEFAULT ROLE labsdbuser FOR '{username}'@'%';
    """
}


def read_replica_cnf(file_path):
    """
    Parse a given replica.my.cnf file

    Return a tuple of mysql username, password_hash
    """
    cp = configparser.ConfigParser()
    cp.read(file_path)
    # sometimes these values have quotes around them
    return (
        cp['client']['user'].strip("'"),
        '*' + sha1(sha1(
            cp['client']['password'].strip("'").encode('utf-8')
        ).digest()).hexdigest()
    )


def find_tools(conn):
    """
    Return list of tools, from canonical LDAP source

    Return a list of tuples of uid, toolname
    """
    conn.search(
        'ou=people,ou=servicegroups,dc=wikimedia,dc=org',
        '(cn=%s.*)' % PROJECT,
        ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
        attributes=['uidNumber', 'cn'],
        time_limit=5
    )

    users = []
    for resp in conn.response:
        attrs = resp['attributes']
        users.append((attrs['cn'][0], int(attrs['uidNumber'][0])))

    return users


def find_users(ldap_conn):
    """
    Return list of users, from canonical LDAP source

    Return a tuple of uid, username
    """
    pass


def get_ldap_conn(config):
    """
    Return a ldap connection

    Return value can be used as a context manager
    """
    servers = ldap3.ServerPool([
        ldap3.Server(host, connect_timeout=1)
        for host in config['ldap']['hosts']
    ], ldap3.POOLING_STRATEGY_ROUND_ROBIN, active=True, exhaust=True)

    return ldap3.Connection(
        servers, read_only=True,
        user=config['ldap']['username'],
        auto_bind=True,
        password=config['ldap']['password']
    )


def get_accounts_db_conn(config):
    """
    Return a pymysql connection to the accounts database
    """
    return pymysql.connect(
        config['accounts-backend']['host'],
        config['accounts-backend']['username'],
        config['accounts-backend']['password'],
        db='labsdbaccounts',
        charset='utf8mb4'
    )


def harvest_cnf_files(config):
    with get_ldap_conn(config) as conn:
        tools = find_tools(conn)
    db = get_accounts_db_conn(config)
    cur = db.cursor()
    try:
        for toolname, uid in tools:
            replica_path = os.path.join(
                '/srv/tools/shared/tools/project/',
                # FIXME: Do this better
                toolname.split('.')[-1],
                'replica.my.cnf'
            )
            if os.path.exists(replica_path):
                mysql_user, pwd_hash = read_replica_cnf(replica_path)
                if mysql_user.startswith('s'):
                    cur.execute("""
                    INSERT INTO account (mysql_username, type, username, password_hash)
                    VALUES (%s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                    password_hash = %s
                    """, (mysql_user, 'tool', toolname, pwd_hash, pwd_hash)
                    )
            else:
                print('no replica for ', toolname)
        db.commit()
    finally:
        cur.close()


def harvest_replica_accts(config):
    db = get_accounts_db_conn(config)
    labsdbs = [
        pymysql.connect(host, config['labsdbs']['username'], config['labsdbs']['password'])
        for host in config['labsdbs']['hosts']
    ]

    with db.cursor(pymysql.cursors.DictCursor) as read_cur:
        read_cur.execute("""
        SELECT id, mysql_username, type, username
        FROM account
        """)
        for row in read_cur:
            for labsdb in labsdbs:
                with labsdb.cursor(pymysql.cursors.DictCursor) as labsdb_cur:
                    try:
                        labsdb_cur.execute("""
                        SHOW GRANTS FOR %s@'%%'
                        """, (row['mysql_username']))
                        labsdb_cur.fetchone()
                        status = 'present'
                    except pymysql.err.InternalError as e:
                        if e.args[0] != 1141:
                            raise
                        logging.info(
                            'No acct found for %s in %s', row['username'], labsdb.host)
                        status = 'absent'
                    with db.cursor() as write_cur:
                        write_cur.execute("""
                        INSERT INTO account_host (account_id, hostname, status)
                        VALUES (%s, %s, %s)
                        ON DUPLICATE KEY UPDATE
                        status = %s
                        """, (row['id'], labsdb.host, status, status))
    db.commit()


def create_accounts(config):
    """
    Find hosts with accounts in absent state, and creates them.
    """
    db = get_accounts_db_conn(config)
    labsdb_hosts = [
        host for host in config['labsdbs']['hosts']
        if config['labsdbs']['hosts'][host]['grant-type'] == 'role'
    ]

    for host in labsdb_hosts:
        labsdb = pymysql.connect(
            host,
            config['labsdbs']['username'],
            config['labsdbs']['password'])
        with db.cursor(pymysql.cursors.DictCursor) as cur:
            cur.execute("""
            SELECT mysql_username, password_hash, username, hostname
            FROM account JOIN account_host on account.id = account_host.account_id
            WHERE hostname = %s AND status = 'absent'
            """, (host, ))
            for row in cur:
                print(host, row['username'])
                print(ACCOUNT_CREATION_SQL['role'].format(
                    username=row['mysql_username'],
                    password_hash=row['password_hash'].decode('utf-8'),
                    max_connections=10,
                ))



if __name__ == '__main__':
    argparser = argparse.ArgumentParser()

    argparser.add_argument('--config',
                           default='/etc/create-dbusers.yaml',
                           help='Path to YAML config file')

    argparser.add_argument('--debug',
                           help='Turn on debug logging',
                           action='store_true')

    args = argparser.parse_args()

    loglvl = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(format='%(message)s',
                        level=loglvl)

    with open(args.config) as f:
        config = yaml.safe_load(f)

    harvest_cnf_files(config)
    create_accounts(config)



