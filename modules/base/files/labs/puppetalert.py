#!/usr/bin/python
# Copyright 2016 Andrew Bogott <andrewbogott@gmail.com> and Yuvi Panda <yuvipanda@gmail.com>
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
Send an alert email to project admins about a puppet failure.  This is
meant to be run on the affected instance.
"""
import argparse
import ldap
import socket
import yaml
import subprocess

with open('/etc/wmflabs-project') as f:
    PROJECT_NAME = f.read().strip()


def connect(server, username, password):
    conn = ldap.initialize('ldap://%s:389' % server)
    conn.protocol_version = ldap.VERSION3
    conn.start_tls_s()
    conn.simple_bind_s(username, password)
    return conn


def get_user_keys(conn, user):
    response = conn.search_s(
        user,
        ldap.SCOPE_BASE
    )
    for _, user in response:
        return user['sshPublicKey']


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


def main():
    with open('/etc/ldap.yaml') as f:
        config = yaml.safe_load(f)

    conn = connect(config['servers'][0], config['user'], config['password'])
    roledn = "cn=projectadmin,cn=%s,ou=projects,%s" % (PROJECT_NAME, config['basedn'])

    hostname = socket.gethostname()

    body = "Puppet is failing to run on the %s instance in the "\
           "Wikimedia Labs project %s."\
           "\n\n"\
           "Working puppet runs are needed to maintain instance security and "\
           "logins.  As long as puppet\ncontinues to fail, this system is in "\
           "danger of becoming unreachable."\
           "\n\n"\
           "You are receiving this email because you are listed as an "\
           "administrator for the project that\ncontains this instance. "\
           " Please take steps to repair this instance or contact a Labs "\
           "admin\nfor assistance."\
		   "\n\n"\
           "For further support, visit #wikimedia-labs on freenode or visit "\
           "http://www.wikitech.org"\
           % (hostname, PROJECT_NAME)
           
    subject = "Alert:  puppet failed on %s.%s.eqiad.wmflabs" % (hostname, PROJECT_NAME)

    adminrec = conn.search_s(
        roledn,
        ldap.SCOPE_BASE
    )
    admins = adminrec[0][1]['roleOccupant']

    for admin in admins:
        userrec = conn.search_s(admin, ldap.SCOPE_BASE)
        email = userrec[0][1]['mail'][0]

        args = ['/usr/bin/mail', '-s', subject, email]

        p = subprocess.Popen(args, stdout=subprocess.PIPE,
                             stdin=subprocess.PIPE, stderr=subprocess.STDOUT)
        p.communicate(input=body)[0]


if __name__ == '__main__':
    main()
