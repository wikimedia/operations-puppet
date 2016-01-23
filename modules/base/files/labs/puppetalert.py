#!/usr/bin/python
# Copyright 2016 Andrew Bogott <andrewbogott@gmail.com> and
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
Send an alert email to project admins about a puppet failure.  This is
meant to be run on the affected instance.
"""
import argparse
import calendar
import time
import ldap
import socket
import yaml
import subprocess

# Nag if it's been 24 hours since the last puppet run
NAG_INTERVAL = 60 * 60 * 24

# Don't bother to notify the novaadmin user; that just
#  sends spam to ops@
USER_IGNORE_LIST = ['uid=novaadmin,ou=people,dc=wikimedia,dc=org']

with open('/etc/wmflabs-project') as f:
    PROJECT_NAME = f.read().strip()


def connect(server, username, password):
    conn = ldap.initialize('ldap://%s:389' % server)
    conn.protocol_version = ldap.VERSION3
    conn.start_tls_s()
    conn.simple_bind_s(username, password)
    return conn


def scold():
    with open('/etc/ldap.yaml') as f:
        config = yaml.safe_load(f)

    conn = connect(config['servers'][0], config['user'], config['password'])
    roledn = "cn=projectadmin,cn=%s,ou=projects,%s" % (PROJECT_NAME,
                                                       config['basedn'])

    hostname = socket.gethostname()

    body = """
Puppet is failing to run on the "{instance}" instance in the Wikimedia Labs
project "{project}"

Working puppet runs are needed to maintain instance security and logins.
As long as puppet continues to fail, this system is in danger of becoming
unreachable.

You are receiving this email because you are listed as an administrator
for the project that contains this instance.  Please take steps to repair
this instance or contact a Labs admin for assistance.

For further support, visit #wikimedia-labs on freenode or visit
http://www.wikitech.org""".format(instance=hostname, project=PROJECT_NAME)

    subject = "Alert:  puppet failed on %s.%s.eqiad.wmflabs" % (hostname,
                                                                PROJECT_NAME)

    adminrec = conn.search_s(
        roledn,
        ldap.SCOPE_BASE
    )
    admins = adminrec[0][1]['roleOccupant']

    for admin in admins:
        if admin.lower() in USER_IGNORE_LIST:
            continue

        userrec = conn.search_s(admin, ldap.SCOPE_BASE)
        email = userrec[0][1]['mail'][0]

        args = ['/usr/bin/mail', '-s', subject, email]

        p = subprocess.Popen(args, stdout=subprocess.PIPE,
                             stdin=subprocess.PIPE, stderr=subprocess.STDOUT)
        p.communicate(input=body)[0]


def lastrun():
    datafile = file('/var/lib/puppet/state/last_run_summary.yaml')
    for line in datafile:
        fields = line.strip().split(': ')
        if fields[0] == 'last_run':
            return int(fields[1])
    return 0


def main():
    elapsed = calendar.timegm(time.gmtime()) - lastrun()
    if elapsed > NAG_INTERVAL:
        print "It has been %s seconds since last puppet run.  "\
              "Sending nag emails." % NAG_INTERVAL
        scold()


if __name__ == '__main__':
    main()
