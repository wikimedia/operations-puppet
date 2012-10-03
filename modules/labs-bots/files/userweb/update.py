#!/usr/bin/python
'''
Nagios labs bot's vhost builder

Author: Damian Zaremba <damian@damianzaremba.co.uk>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
'''
# Import modules we need
import re
import sys
import os
import ldap
import logging
from pwd import getpwnam
from optparse import OptionParser

# Our base dir
base_dir = "/data/project/public_html/"

# Allowed vhosts
ok_vhosts = ['wm-bot']

# Excluded users
ignore_users = ['novaadmin']

# How much to spam
logging_level = logging.INFO

# LDAP details
ldap_config_file = "/etc/ldap.conf"
ldap_base_dn = "dc=wikimedia,dc=org"
ldap_filter = '(&(objectClass=groupofnames)(cn=bots))'
ldap_attrs = ['member', 'cn']

# Setup logging, everyone likes logging
formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
stdout_handler = logging.StreamHandler(sys.stdout)
stdout_handler.setFormatter(formatter)
logger = logging.getLogger(__name__)
logger.setLevel(logging_level)
logger.addHandler(stdout_handler)


def get_ldap_config():
    '''
    Simple function to load the ldap config into a dict
    '''
    ldap_config = {}
    with open(ldap_config_file, 'r') as fh:
        for line in fh.readlines():
            line_parts = line.split(' ', 1)

            if len(line_parts) == 2:
                ldap_config[line_parts[0].strip()] = line_parts[1].strip()

    return ldap_config


def ldap_connect():
    '''
    Simple function to connect to ldap
    '''
    ldap_config = get_ldap_config()
    if 'uri' not in ldap_config:
        logger.error('Could get URI from ldap config')
        return False

    if 'binddn' not in ldap_config or 'bindpw' not in ldap_config:
        logger.error('Could get bind details from ldap config')
        return False

    ldap_connection = ldap.initialize(ldap_config['uri'])
    ldap_connection.start_tls_s()

    try:
        ldap_connection.simple_bind_s(ldap_config['binddn'],
                                      ldap_config['bindpw'])
    except ldap.LDAPError:
        logger.error('Could not bind to LDAP')
    else:
        logger.debug('Connected to ldap')
        return ldap_connection


def ldap_disconnect(ldap_connection):
    '''
    Simple function to disconnect from ldap
    '''
    try:
        ldap_connection.unbind_s()
    except ldap.LDAPError:
        logger.error('Could not cleanly disconnect from LDAP')
    else:
        logger.debug('Disconnected from ldap')

if __name__ == "__main__":
    parser = OptionParser()
    parser.add_option('-d', '--debug', action='store_true', dest='debug')

    (options, args) = parser.parse_args()
    if options.debug:
        logger.setLevel(logging.DEBUG)

    # Connect
    ldap_connection = ldap_connect()
    if ldap_connection:
        # Get the users
        logger.debug('Searching ldap for hosts')
        results = ldap_connection.search_s(ldap_base_dn, ldap.SCOPE_SUBTREE,
                                           ldap_filter, ldap_attrs)

        if not results:
            logger.error('Could not get the list of hosts from ldap')
            sys.exit(1)

        for (dn, project) in results:
            logger.debug('Processing info for %s' % dn)

        for member in project['member']:
            # We could do another ldap search here but that seems wasteful
            matches = re.match(r'uid=(.+),ou=people,.+', member)
            if not matches or not matches.group(1):
                logger.error('Could not understand %s' % member)
                continue

            username = matches.group(1)
            if username in ignore_users:
                logger.info('Skipping %s as it\'s ignored' % username)
                continue

            ok_vhosts.append(username)

            path = os.path.join(base_dir, username)
            if not os.path.exists(path):
                logger.info('%s does not exist, creating' % path)
                os.makedirs(path)

                if not os.path.exists(path):
                    logger.error('Failed to create %s' % path)
                    continue
                logger.info('Created %s successfully' % path)

            uid = getpwnam(username).pw_uid
            gid = getpwnam('www-data').pw_uid

            if not uid or not gid:
                logger.error('Could not get uid or gid for %s' % uid)
                continue

            logger.info('Chowning %s to %d.%d' % (path, uid, gid))
            os.chown(path, uid, gid)

        for vhost in os.listdir(base_dir):
            if vhost not in ok_vhosts:
                logger.info('%s appears to be bad, disabling' % vhost)
                os.chmod(os.path.join(base_dir, vhost), 000)
                os.chown(os.path.join(base_dir, vhost), 0, 0)

    ldap_disconnect(ldap_connection)
