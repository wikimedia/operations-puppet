#!/usr/bin/python3
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
import mwopenstackclients
import socket
import yaml
import subprocess

# Don't bother to notify the novaadmin and nova-tools-bot user as it spams ops@
# and noc@, respectively
USER_IGNORE_LIST = [
    "uid=novaadmin,ou=people,dc=wikimedia,dc=org",
    "uid=nova-tools-bot,ou=people,dc=wikimedia,dc=org",
]


def connect(server, username, password):
    conn = ldap.initialize("ldap://%s:389" % server)
    conn.protocol_version = ldap.VERSION3
    conn.start_tls_s()
    conn.simple_bind_s(username, password)
    return conn


with open("/etc/wmcs-project") as f:
    project_name = f.read().strip()


with open("/etc/ldap.yaml") as f:
    ldap_config = yaml.safe_load(f)


ldap_conn = connect(
    ldap_config["servers"][0], ldap_config["user"], ldap_config["password"]
)


def email_admins(subject, msg):
    keystoneclient = mwopenstackclients.Clients(oscloud='novaobserver').keystoneclient()
    roleid = None
    for r in keystoneclient.roles.list():
        if r.name == "member":
            roleid = r.id
            break

    assert roleid is not None
    for ra in keystoneclient.role_assignments.list(project=project_name, role=roleid):
        dn = "uid={},ou=people,{}".format(ra.user["id"], ldap_config["basedn"])
        _email_member(dn, subject, msg)


def email_members(subject, msg):
    roledn = "cn=%s,ou=groups,%s" % ("project-" + project_name, ldap_config["basedn"])

    member_rec = ldap_conn.search_s(roledn, ldap.SCOPE_BASE)
    members = member_rec[0][1]["member"]

    for member in members:
        _email_member(member.decode(), subject, msg)


def _email_member(member, subject, body):
    if member.lower() in USER_IGNORE_LIST:
        return

    userrec = ldap_conn.search_s(member, ldap.SCOPE_BASE)
    email = userrec[0][1]["mail"][0]

    args = ["/usr/bin/mail", "-s", subject, "-a", "Precedence: Bulk", email.decode()]

    p = subprocess.Popen(
        args, stdout=subprocess.PIPE, stdin=subprocess.PIPE, stderr=subprocess.STDOUT
    )
    p.communicate(input=body.encode('utf8'))[0]


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("-s", help="email subject", default=None)
    parser.add_argument("-m", help="email message", default=None)
    parser.add_argument("--admins-only", help="admins only", action="store_true")
    args = parser.parse_args()

    if args.m is None:
        # if stdin is empty we bail
        if sys.stdin.isatty():
            sys.exit("no stdin and no message specified")
        # Reading in the message
        args.m = sys.stdin.read()

    if args.s is None:
        args.s = "[WMCS notice] Project members for %s" % (socket.gethostname())

    if args.admins_only:
        email_admins(args.s, args.m)
    else:
        email_members(args.s, args.m)


if __name__ == "__main__":
    main()
