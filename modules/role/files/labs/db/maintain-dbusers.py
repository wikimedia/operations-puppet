#!/usr/bin/python3
"""
This script keeps canonical source of mysql labsdb accounts in a
database, and ensures that it is kept up to date with reality.

The code pattern here is that you have a central data store (the db),
that is then read/written to by various independent functions. These
functions are not 'pure' - they could even be separate scripts. They
mutate the DB in some way. They are also supposed to be idempotent -
if they have nothing to do, they should not do anything.

Some of the functions are one-time only, allowing migration from
create-dbusers. These are:

## harvest_cnf_files ##

 - Look through NFS for replica.my.cnf files
 - For those found, but no entry in `accounts` table, make an entry

## harvest_dbaccounts ##
 - Look through all accounts in account db
 - Look through all users in all provisioned labsdbs
 - Make entries in `account_host` table with status of all accounts.

Most of these functions should be run in a continuous loop, maintaining
mysql accounts for new tool accounts as they appear.

## populate_new_tools ##

 - Find list of tools (From LDAP) that aren't in the `accounts` table
 - Create a replica.my.cnf for each of these tools
 - Make an entry in the `accounts` table for each of these tools
 - Make entries in `account_host` for each of these tools, marking them as
   absent

## create_accounts ##

 - Look through `account_host` table for accounts that are marked as 'absent'
 - Create those accounts, and mark them as present.

If we need to add a new labsdb, we can do so the following way:
 - Add it to the config file
 - Insert entries into `account_host` for each tool with the new host.
 - Run `create_accounts`

In normal usage, just a continuous process running `populate_new_tools` and
`create_accounts` in a loop will suffice.

TODO:
  - Support for maintaining per-tool restrictions (number of connections + time)
"""
import sys
import ldap3
import logging
import argparse
import string
import io
import yaml
import configparser
import os
import time
import pymysql
import random
from hashlib import sha1
import subprocess

PROJECT = 'tools'
PASSWORD_LENGTH = 16
PASSWORD_CHARS = string.ascii_letters + string.digits
ACCOUNT_CREATION_SQL = {
    'role': """
        GRANT USAGE ON *.* TO '{username}'@'%'
              IDENTIFIED BY PASSWORD '{password_hash}'
              WITH MAX_USER_CONNECTIONS {max_connections};
        GRANT labsdbuser TO '{username}'@'%';
        SET DEFAULT ROLE labsdbuser FOR '{username}'@'%';
    """,
    'legacy': """
        CREATE USER '{username}'@'%'
               IDENTIFIED BY PASSWORD '{password_hash}';
        GRANT SELECT, SHOW VIEW ON `%\_p`.* TO '{username}'@'%';
        GRANT ALL PRIVILEGES ON `{username}\_\_%`.* TO '{username}'@'%';
    """
}


def generate_new_pw():
    """
    Generate a new random password
    """
    sysrandom = random.SystemRandom()  # Uses /dev/urandom
    return ''.join([sysrandom.choice(PASSWORD_CHARS) for _ in range(PASSWORD_LENGTH)])


def mysql_hash(password):
    """
    Hash a password to mimic MySQL's PASSWORD() function
    """
    return '*' + sha1(sha1(password.encode('utf-8')).digest()).hexdigest()


def write_replica_cnf(file_path, uid, mysql_username, pwd):
    """
    Write a replica.my.cnf file.

    Will also set the 'immutable' attribute on the file, so users
    can not fuck up their own replica.my.cnf files accidentally.
    """
    replica_config = configparser.ConfigParser()

    replica_config['client'] = {
        'user': mysql_username,
        'password': pwd
    }
    # Because ConfigParser can only write to a file
    # and not just return the value as a string directly
    replica_buffer = io.StringIO()
    replica_config.write(replica_buffer)

    f = os.open(file_path, os.O_CREAT | os.O_WRONLY | os.O_NOFOLLOW)
    try:
        os.write(f, replica_buffer.getvalue().encode('utf-8'))
        # uid == gid
        os.fchown(f, uid, uid)
        os.fchmod(f, 0o400)

        # Prevent removal or modification of the credentials file by users
        subprocess.check_output(['/usr/bin/chattr', '+i', file_path])
    except:
        os.remove(file_path)
        raise
    finally:
        os.close(f)


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
        mysql_hash(cp['client']['password'].strip("'"))
    )


def find_tools(config):
    """
    Return list of tools, from canonical LDAP source

    Return a list of tuples of uid, toolname
    """
    with get_ldap_conn(config) as conn:
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
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )


def get_replica_path(type, name):
    """
    Return path to use for replica.my.cnf for a tool or user
    """
    if type == 'tool':
        return os.path.join(
            '/srv/tools/shared/tools/project/',
            name[len(PROJECT) + 1:],  # Remove `PROJECT.` prefix from name
            'replica.my.cnf'
        )
    else:
        return os.path.join(
            '/srv/tools/shared/tools/home/',
            name,
            'replica.my.cnf'
        )


def harvest_cnf_files(config):
    tools = find_tools(config)
    acct_db = get_accounts_db_conn(config)
    cur = acct_db.cursor()
    try:
        for toolname, uid in tools:
            replica_path = get_replica_path('tool', toolname)
            if os.path.exists(replica_path):
                mysql_user, pwd_hash = read_replica_cnf(replica_path)
                cur.execute("""
                INSERT INTO account (mysql_username, type, username, password_hash)
                VALUES (%s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                password_hash = %s
                """, (mysql_user, 'tool', toolname, pwd_hash, pwd_hash)
                )
            else:
                logging.info('Found no replica.my.cnf to harvest for %s', toolname)
        acct_db.commit()
    finally:
        cur.close()


def harvest_replica_accts(config):
    acct_db = get_accounts_db_conn(config)
    labsdbs = [
        pymysql.connect(host, config['labsdbs']['username'], config['labsdbs']['password'])
        for host in config['labsdbs']['hosts']
    ]

    with acct_db.cursor() as read_cur:
        read_cur.execute("""
        SELECT id, mysql_username, type, username
        FROM account
        """)
        for row in read_cur:
            for labsdb in labsdbs:
                with labsdb.cursor() as labsdb_cur:
                    try:
                        labsdb_cur.execute("""
                        SHOW GRANTS FOR %s@'%%'
                        """, (row['mysql_username']))
                        labsdb_cur.fetchone()
                        status = 'present'
                    except pymysql.err.InternalError as e:
                        # Error code for when no grants exist for this username
                        if e.args[0] != 1141:
                            raise
                        logging.info(
                            'No acct found for %s in %s', row['username'], labsdb.host)
                        status = 'absent'
                    with acct_db.cursor() as write_cur:
                        write_cur.execute("""
                        INSERT INTO account_host (account_id, hostname, status)
                        VALUES (%s, %s, %s)
                        ON DUPLICATE KEY UPDATE
                        status = %s
                        """, (row['id'], labsdb.host, status, status))
    acct_db.commit()


def populate_new_tools(config):
    """
    Populate new tools into meta db
    """
    all_tools = find_tools(config)
    acct_db = get_accounts_db_conn(config)
    with acct_db.cursor() as cur:
        cur.execute("""
        SELECT username FROM account
        """)
        cur_tools = set([r['username'] for r in cur])

        new_tools = [t for t in all_tools if t[0] not in cur_tools]

        logging.info('Found %s new tools: %s',
                     len(new_tools),
                     ', '.join([t[0] for t in new_tools]))
        for new_tool, new_tool_id in new_tools:
            # if a homedir for this tool does not exist yet, just ignore it
            # home directory creation is currently handled by maintain-kubeusers, and we
            # do not want to race. Tool accounts that get passed over like this will be
            # picked up on the next round
            replica_path = get_replica_path('tool', new_tool)
            if not os.path.exists(os.path.dirname(replica_path)):
                logging.info('Skipping tool %s, since no home directory exists yet', new_tool)
            pwd = generate_new_pw()
            mysql_username = 's%d' % new_tool_id
            cur.execute("""
            INSERT INTO account (mysql_username, type, username, password_hash)
            VALUES (%s, %s, %s, %s)
            """, (
                mysql_username,
                'tool',
                new_tool,
                mysql_hash(pwd)
            ))
            acct_id = cur.lastrowid
            for hostname in config['labsdbs']['hosts']:
                cur.execute("""
                INSERT INTO account_host (account_id, hostname, status)
                VALUES (%s, %s, %s)
                """, (acct_id, hostname, 'absent'))
            # Do this *before* the commit to the db has succeeded
            write_replica_cnf(
                replica_path,
                new_tool_id,
                mysql_username,
                pwd
            )
            acct_db.commit()
            logging.info('Wrote replica.my.cnf for %s', new_tool)


def create_accounts(config):
    """
    Find hosts with accounts in absent state, and creates them.
    """
    acct_db = get_accounts_db_conn(config)

    for host in config['labsdbs']['hosts']:
        labsdb = pymysql.connect(
            host,
            config['labsdbs']['username'],
            config['labsdbs']['password'])
        grant_type = config['labsdbs']['hosts'][host]['grant-type']
        with acct_db.cursor() as cur:
            cur.execute("""
            SELECT mysql_username, password_hash, username, hostname,
                   account_host.id as account_host_id
            FROM account JOIN account_host on account.id = account_host.account_id
            WHERE hostname = %s AND status = 'absent'
            """, (host, ))
            for row in cur:
                with labsdb.cursor() as labsdb_cur:
                    labsdb_cur.execute(
                        ACCOUNT_CREATION_SQL[grant_type].format(
                            username=row['mysql_username'],
                            password_hash=row['password_hash'].decode('utf-8'),
                            max_connections=10,
                        ))
                    labsdb.commit()
                with acct_db.cursor() as write_cur:
                    write_cur.execute("""
                    UPDATE account_host
                    SET status='present'
                    WHERE id = %s
                    """, (row['account_host_id'],))
                    acct_db.commit()
                    logging.info('Created account in %s for %s', host, row['username'])


def delete_account(config, account):
    """
    Deletes a mysql user account

    - Deletes replica.my.cnf
    - Removes them from accounts db
    - Drops users from labsdbs
    """
    acct_db = get_accounts_db_conn(config)

    for host in config['labsdbs']['hosts']:
        labsdb = pymysql.connect(
            host,
            config['labsdbs']['username'],
            config['labsdbs']['password'])
        with acct_db.cursor() as cur:
            cur.execute("""
            SELECT mysql_username, password_hash, username, hostname,
                   account_host.id as account_host_id
            FROM account JOIN account_host on account.id = account_host.account_id
            WHERE hostname = %s AND username = %s AND status = 'present'
            """, (host, account))
            for row in cur:
                with labsdb.cursor() as labsdb_cur:
                    labsdb_cur.execute("DROP USER %s" % row['mysql_username'])
                    labsdb.commit()
                with acct_db.cursor() as write_cur:
                    write_cur.execute("""
                    DELETE FROM account_host
                    WHERE id = %s
                    """, (row['account_host_id'],))
                    acct_db.commit()
                    logging.info('Deleted account in %s for %s', host, row['username'])

    # Now we get rid of the file
    replica_file_path = get_replica_path('tool', account)
    subprocess.check_output(['/usr/bin/chattr', '-i', replica_file_path])
    os.remove(replica_file_path)
    logging.info('Deleted %s', replica_file_path)

    # Now we get rid of the account itself
    with acct_db.cursor() as write_cur:
        write_cur.execute("""
        DELETE FROM account
        WHERE type=%s AND username=%s
        """, ('tool', account))
        acct_db.commit()

if __name__ == '__main__':
    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        '--config',
        default='/etc/dbusers.yaml',
        help='Path to YAML config file'
    )

    argparser.add_argument(
        '--debug',
        help='Turn on debug logging',
        action='store_true'
    )
    argparser.add_argument(
        'action',
        choices=['harvest', 'maintain', 'delete'],
        help="""
        What action to take.

        harvest:

        Collect information about all existing users from replica.my.cnf files
        and accounts already created in legacy databases, and put them into the
        account database. Runs as a one shot script.

        maintain:

        Runs as a daemon that watches for new tools being created, creates accounts
        for them in all the labsdbs, maintains state in the account database, and
        writes out replica.my.cnf files.

        delete:

        Deletes a given user. Provide a username like tools.admin,
        not a mysql user name.
        """
    )
    argparser.add_argument(
        'extra_args',
        nargs='?',
        help="""
        Optional argument used when more info needs to be passed in.

        Currently used with `delete` to pass in a username.
        """
    )
    args = argparser.parse_args()

    loglvl = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(format='%(message)s',
                        level=loglvl)

    with open(args.config) as f:
        config = yaml.safe_load(f)

    if args.action == 'harvest':
        harvest_cnf_files(config)
        harvest_replica_accts(config)
    elif args.action == 'maintain':
        while True:
            populate_new_tools(config)
            create_accounts(config)
            time.sleep(60)
    elif args.action == 'delete':
        if args.extra_args is None:
            logging.error('Need to provide username to delete')
            sys.exit(1)
        delete_account(config, args.extra_args)
