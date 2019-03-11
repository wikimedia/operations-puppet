#!/usr/bin/python
#
#   Copyright 2016
#   Andrew Bogott <andrewbogott@gmail.com>
#   Yuvi Panda <yuvipanda@gmail.com>
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
Send email alerts to project members -- run on the affected instance
"""
import sys
import argparse
import ldap
import socket
import yaml
import subprocess

from keystoneclient.auth.identity.v3 import Password as KeystonePassword
from keystoneclient.session import Session as KeystoneSession
from keystoneclient.v3 import client as keystone_client

# Don't bother to notify the novaadmin user as it spams ops@
USER_IGNORE_LIST = ['uid=novaadmin,ou=people,dc=wikimedia,dc=org']


def connect(server, username, password):
    conn = ldap.initialize('ldap://%s:389' % server)
    conn.protocol_version = ldap.VERSION3
    conn.start_tls_s()
    conn.simple_bind_s(username, password)
    return conn


with open('/etc/wmflabs-project') as f:
    project_name = f.read().strip()


with open('/etc/ldap.yaml') as f:
    ldap_config = yaml.safe_load(f)


with open('/etc/novaobserver.yaml') as n:
    nova_observer_config = yaml.safe_load(n)


ldap_conn = connect(ldap_config['servers'][0], ldap_config['user'], ldap_config['password'])


def email_admins(subject, msg):
    keystone_session = KeystoneSession(auth=KeystonePassword(
        auth_url=nova_observer_config['OS_AUTH_URL'],
        username=nova_observer_config['OS_USERNAME'],
        password=nova_observer_config['OS_PASSWORD'],
        project_name=nova_observer_config['OS_PROJECT_NAME'],
        user_domain_name='default',
        project_domain_name='default'
    ))
    keystoneclient = keystone_client.Client(session=keystone_session, interface='public')
    roleid = None
    for r in keystoneclient.roles.list():
        if r.name == 'projectadmin':
            roleid = r.id
            break

    assert roleid is not None
    for ra in keystoneclient.role_assignments.list(project=project_name, role=roleid):
        dn = 'uid={},ou=people,{}'.format(ra.user['id'], ldap_config['basedn'])
        _email_member(dn, subject, msg)


def email_members(subject, msg):
    roledn = 'cn=%s,ou=groups,%s' % ('project-' + project_name,
                                     ldap_config['basedn'])

    member_rec = ldap_conn.search_s(
        roledn,
        ldap.SCOPE_BASE
    )
    members = member_rec[0][1]['member']

    for member in members:
        _email_member(member, subject, msg)


def _email_member(member, subject, body):
    if member.lower() in USER_IGNORE_LIST:
        return

    userrec = ldap_conn.search_s(member, ldap.SCOPE_BASE)
    email = userrec[0][1]['mail'][0]

    args = ['/usr/bin/mail', '-s', subject, email]

    p = subprocess.Popen(args, stdout=subprocess.PIPE,
                         stdin=subprocess.PIPE, stderr=subprocess.STDOUT)
    p.communicate(input=body)[0]


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument('-s', help='email subject', default=None)
    parser.add_argument('-m', help='email message', default=None)
    parser.add_argument('--admins-only', help='admins only', action='store_true')
    args = parser.parse_args()

    if args.m is None:
        # if stdin is empty we bail
        if sys.stdin.isatty():
            sys.exit('no stdin and no message specified')
        # Reading in the message
        args.m = sys.stdin.read()

    if args.s is None:
        args.s = "[WMCS notice] Project members for %s" % (socket.gethostname())

    if args.admins_only:
        email_admins(args.s, args.m)
    else:
        email_members(args.s, args.m)


if __name__ == '__main__':
    main()
