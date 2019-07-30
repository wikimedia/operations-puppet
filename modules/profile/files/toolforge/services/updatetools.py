#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse
import errno
import logging
import os
import time

import ldap3
import pymysql
import yaml


PAGE_COOKIE = '1.2.840.113556.1.4.319'
logger = logging.getLogger(__name__)


def get_tools_from_ldap(conn, project):
    """Build dict of all tools from LDAP"""
    tools = {}
    name_offset = len(project) + 1
    search_params = {
        'search_base': 'ou=people,ou=servicegroups,dc=wikimedia,dc=org',
        'search_filter': '(&(objectClass=posixAccount)(cn=%s.*))' % project,
        'search_scope': ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
        'attributes': ['cn', 'uidNumber', 'homeDirectory'],
        'time_limit': 5,
        'paged_size': 256,
    }
    while True:
        conn.search(**search_params)
        for resp in conn.response:
            attrs = resp['attributes']
            name = attrs['cn'][0][name_offset:]
            tools[name] = {
                'name': name,
                'id': attrs['uidNumber'][0],
                'home': attrs['homeDirectory'][0],
                'maintainers': [],
            }
        cookie = conn.result['controls'][PAGE_COOKIE]['value']['cookie']
        if cookie:
            search_params['paged_cookie'] = cookie
        else:
            break

    search_params = {
        'search_base': 'ou=servicegroups,dc=wikimedia,dc=org',
        'search_filter': '(&(objectClass=posixGroup)(cn=%s.*))' % project,
        'search_scope': ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
        'attributes': ['cn', 'member'],
        'time_limit': 5,
        'paged_size': 256,
    }
    while True:
        conn.search(**search_params)
        for resp in conn.response:
            attrs = resp['attributes']
            name = attrs['cn'][0][name_offset:]
            if name in tools:
                tools[name]['maintainers'].extend([
                    dn.split(',')[0].split('=')[1] for dn in attrs['member']])
        cookie = conn.result['controls'][PAGE_COOKIE]['value']['cookie']
        if cookie:
            search_params['paged_cookie'] = cookie
        else:
            break
    return tools


def get_users_from_ldap(conn, project):
    """Build dict of all project members from LDAP"""
    users = {}
    search_params = {
        'search_base': 'ou=people,dc=wikimedia,dc=org',
        'search_filter': (
            '(&(objectClass=posixAccount)'
            '(memberOf=cn=project-%s,ou=groups,dc=wikimedia,dc=org))'
        ) % project,
        'search_scope': ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
        'attributes': ['uid', 'cn', 'uidNumber', 'homeDirectory'],
        'time_limit': 5,
        'paged_size': 256,
    }
    while True:
        conn.search(**search_params)
        for resp in conn.response:
            attrs = resp['attributes']
            name = attrs['uid'][0]
            users[name] = {
                'name': name,
                'id': attrs['uidNumber'][0],
                'wikitech': attrs['cn'][0],
                'home': attrs['homeDirectory'][0],
            }
        cookie = conn.result['controls'][PAGE_COOKIE]['value']['cookie']
        if cookie:
            search_params['paged_cookie'] = cookie
        else:
            break

    return users


def update_tools_table(db, ldap_conn, project):
    def read_normalized_file(path, default=None):
        try:
            with open(path, 'r') as f:
                return ' '.join(l.rstrip('\n') for l in f.readlines())
        except IOError as e:
            if e.errno in (errno.EACCES, errno.ENOENT):
                return default
            raise

    def get_tool_description(homedir):
        return read_normalized_file(homedir + '/.description', '')

    def get_tool_toolinfo(homedir):
        return read_normalized_file(
            homedir + '/toolinfo.json',
            read_normalized_file(homedir + '/public_html/toolinfo.json', ''))

    # Get list of all accounts starting with "tools.".
    tools = get_tools_from_ldap(ldap_conn, project)
    if not tools:
        raise Exception("No tool accounts found. LDAP busted?")

    # Update tools table.
    with db.cursor() as cur:
        db.begin()
        cur.execute('DELETE FROM tools')
        inserted = cur.executemany(
            (
                'INSERT INTO tools ('
                'name, id, home, maintainers, description, toolinfo, updated'
                ') VALUES (%s, %s, %s, %s, %s, %s, UNIX_TIMESTAMP())'
            ),
            [
                (
                    tool['name'],
                    tool['id'],
                    tool['home'],
                    ' '.join(tool['maintainers']),
                    get_tool_description(tool['home']),
                    get_tool_toolinfo(tool['home']),
                ) for tool in tools.values()
            ]
        )
        logger.info("Inserted %d tools", inserted)
    db.commit()


def update_users_table(db, ldap_conn, project):
    # Get list of all accounts in the project-tools group.
    members = get_users_from_ldap(ldap_conn, project)
    if not members:
        raise Exception("No user accounts found. LDAP busted?")

    # Update users table.
    with db.cursor() as cur:
        db.begin()
        cur.execute('DELETE FROM users')
        inserted = cur.executemany(
            (
                'INSERT INTO users ('
                'name, id, wikitech, home'
                ') VALUES (%(name)s, %(id)s, %(wikitech)s, %(home)s)'
            ),
            members.values()
        )
        logger.info("Inserted %d users", inserted)
    db.commit()


def main():
    argparser = argparse.ArgumentParser()
    argparser.add_argument(
        '--ldapconf', default='/etc/ldap.yaml',
        help='Path to YAML LDAP config file')
    argparser.add_argument(
        '-v', '--verbose', action='store_const', dest='loglevel',
        const=logging.DEBUG, default=logging.INFO,
        help='Verbose output')
    argparser.add_argument(
        '--project', default='tools',
        help='Project name to fetch LDAP users from')
    argparser.add_argument(
        '--interval', default=900,
        help='Seconds between between runs')
    argparser.add_argument(
        '--once', action='store_true',
        help='Run once and exit')
    args = argparser.parse_args()

    logging.basicConfig(format='%(message)s', level=args.loglevel)

    with open(args.ldapconf, encoding='utf-8') as f:
        ldapconf = yaml.safe_load(f)

    while True:
        logger.info("Starting a run...")
        logger.debug("Connecting to ToolsDB...")
        db = pymysql.connect(
            host='tools.db.svc.eqiad.wmflabs',
            db='toollabs_p',
            read_default_file=os.path.expanduser("~/replica.my.cnf"),
            charset='utf8mb4',
        )
        logger.debug("Connecting to LDAP...")
        ldap_servers = ldap3.ServerPool(
            [ldap3.Server(s, connect_timeout=1) for s in ldapconf['servers']],
            ldap3.POOLING_STRATEGY_ROUND_ROBIN,
            active=True,
            exhaust=True,
        )
        with ldap3.Connection(
            ldap_servers,
            read_only=True,
            user=ldapconf['user'],
            auto_bind=True,
            password=ldapconf['password'],
            raise_exceptions=True,
        ) as ldap_conn:
            logger.debug("Updating tools table...")
            update_tools_table(db, ldap_conn, args.project)
            logger.debug("Updating users table...")
            update_users_table(db, ldap_conn, args.project)
        db.close()

        if args.once:
            logger.info("Exiting because of --once flag")
            break
        logger.debug("Sleeping for %d seconds", args.interval)
        time.sleep(args.interval)


if __name__ == '__main__':
    main()
