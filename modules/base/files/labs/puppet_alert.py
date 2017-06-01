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
import sys
sys.path.append('/usr/local/sbin/')
from notify_maintainers import email_admins
import calendar
import time
import ldap
import socket

# Nag if it's been 24 hours since the last puppet run
NAG_INTERVAL = 60 * 60 * 24

# Don't bother to notify the novaadmin user; that just
#  sends spam to ops@
USER_IGNORE_LIST = ['uid=novaadmin,ou=people,dc=wikimedia,dc=org']


def connect(server, username, password):
    conn = ldap.initialize('ldap://%s:389' % server)
    conn.protocol_version = ldap.VERSION3
    conn.start_tls_s()
    conn.simple_bind_s(username, password)
    return conn


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

        fqdn = socket.getfqdn()

        subject = "[WMFlabs alert] puppet failure on %s" % (fqdn,)

        print "It has been %s seconds since last puppet run." \
            "Sending nag emails." % NAG_INTERVAL

        body = """
Puppet is failing to run on the "{fqdn}" instance in Wikimedia Labs.

Working puppet runs are needed to maintain instance security and logins.
As long as puppet continues to fail, this system is in danger of becoming
unreachable.

You are receiving this email because you are listed as an administrator
for the project that contains this instance.  Please take steps to repair
this instance or contact a Labs admin for assistance.

For further support, visit #wikimedia-cloud on freenode or visit
https://wikitech.wikimedia.org
""".format(fqdn=fqdn)

        email_admins(subject, body)


if __name__ == '__main__':
    main()
