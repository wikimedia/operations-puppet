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

# Don't bother to notify the novaadmin user as it spams ops@
USER_IGNORE_LIST = ['uid=novaadmin,ou=people,dc=wikimedia,dc=org']


def connect(server, username, password):
    conn = ldap.initialize('ldap://%s:389' % server)
    conn.protocol_version = ldap.VERSION3
    conn.start_tls_s()
    conn.simple_bind_s(username, password)
    return conn


def email_members(subject, msg):

    with open('/etc/wmflabs-project') as f:
        project_name = f.read().strip()

    with open('/etc/ldap.yaml') as f:
        config = yaml.safe_load(f)

    # Ignore certain projects (T218009)
    if project_name in ['tools', 'bastion']:
        return

    conn = connect(config['servers'][0], config['user'], config['password'])
    roledn = 'cn=%s,ou=groups,%s' % ('project-' + project_name,
                                     config['basedn'])

    body = msg

    member_rec = conn.search_s(
        roledn,
        ldap.SCOPE_BASE
    )
    members = member_rec[0][1]['member']

    for member in members:
        if member.lower() in USER_IGNORE_LIST:
            continue

        userrec = conn.search_s(member, ldap.SCOPE_BASE)
        email = userrec[0][1]['mail'][0]

        args = ['/usr/bin/mail', '-s', subject, email]

        p = subprocess.Popen(args, stdout=subprocess.PIPE,
                             stdin=subprocess.PIPE, stderr=subprocess.STDOUT)
        p.communicate(input=body)[0]


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument('-s', help='email subject', default=None)
    parser.add_argument('-m', help='email message', default=None)
    args = parser.parse_args()

    if args.m is None:
        # if stdin is empty we bail
        if sys.stdin.isatty():
            sys.exit('no stdin and no message specified')
        # Reading in the message
        args.m = sys.stdin.read()

    if args.s is None:
        args.s = "[WMCS notice] Project members for %s" % (socket.gethostname())

    email_members(args.s, args.m)


if __name__ == '__main__':
    main()
