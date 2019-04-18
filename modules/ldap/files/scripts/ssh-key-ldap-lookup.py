#!/usr/bin/python
# Copyright 2015 Yuvi Panda <yuvipanda@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""
Takes a user as a parameter and prints list of allowed ssh keys
for that user from querying LDAP.

We just let all errors crash the script since that makes it
exit with a non zero status code and thus prevents login, which
is the behavior we want
"""
import argparse
import os.path
import sys

import ldap
import yaml


DISABLED_PWDPOLICY = "cn=disabled,ou=ppolicies,dc=wikimedia,dc=org"

with open('/etc/wmflabs-project') as f:
    PROJECT_NAME = f.read().strip()


def connect(server, username, password):
    conn = ldap.initialize('ldap://%s:389' % server)
    conn.set_option(ldap.OPT_NETWORK_TIMEOUT, 3.0)
    conn.set_option(ldap.OPT_TIMEOUT, 5)
    conn.protocol_version = ldap.VERSION3
    conn.start_tls_s()
    conn.simple_bind_s(username, password)
    return conn


def get_user_keys(conn, user):
    try:
        response = conn.search_s(
            user,
            ldap.SCOPE_BASE,
            filterstr=(
                "(&"
                "(objectClass=ldapPublicKey)"
                "(!(pwdPolicySubentry={}))"
                ")"
            ).format(DISABLED_PWDPOLICY),
            attrlist=['sshPublicKey'],
        )
    except ldap.NO_SUCH_OBJECT:
        response = None
    if response:
        return response[0][1].get('sshPublicKey', [])
    return []


def get_group_keys(conn, groupname):
    response = conn.search_s(
        groupname,
        ldap.SCOPE_BASE
    )
    # only one service group can have that name
    assert len(response) <= 1
    if response:
        sg = response[0][1]
        keys = []
        for member in sg['member']:
            keys += get_user_keys(conn, member)
        return keys
    else:
        return []


def robust_connect(servers, user, password, position=0):
    try:
        return connect(servers[position], user, password)
    except ldap.SERVER_DOWN:
        if position == len(servers) - 1:
            return
        position += 1
        return robust_connect(servers, user, password, position)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('username', help='Username to list ssh keys for')
    parser.add_argument(
        '--enable-servicegroups',
        action='store_true',
        default=False,
        help='Allow direct ssh login for service groups',
    )
    args = parser.parse_args()

    # Skip LDAP lookup for the root user.
    if args.username == 'root' and not args.enable_servicegroups:
        return

    # Deny authorization for non-root users if the /etc/block-ldap-key-lookup
    # file is present
    if os.path.isfile('/etc/block-ldap-key-lookup'):
        sys.exit(1)

    with open('/etc/ldap.yaml') as f:
        config = yaml.safe_load(f)

    conn = robust_connect(config['servers'],
                          config['user'],
                          config['password'])

    if not conn:
        sys.exit(1)

    if args.enable_servicegroups and args.username.startswith(PROJECT_NAME + '.'):
        groupname = 'cn=%s,ou=servicegroups,%s' % (
            args.username, config['basedn']
        )
        keys = get_group_keys(conn, groupname)
    else:
        username = 'uid=%s,ou=people,%s' % (args.username, config['basedn'])
        keys = get_user_keys(conn, username)
    for key in keys:
        # Some keys have an accidental newline at the end, see T77902
        print key.strip()


if __name__ == '__main__':
    main()
