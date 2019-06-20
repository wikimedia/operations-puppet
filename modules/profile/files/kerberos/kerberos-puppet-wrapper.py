#!/usr/bin/env python3

import sys
import socket
import subprocess

keytabs = {
    'hdfs': '/etc/security/keytabs/hadoop/hdfs.keytab',
    'oozie': '/etc/security/keytabs/oozie/oozie.keytab',
    'analytics': '/etc/security/keytabs/analytics/analytics.keytab'
}

realm_name = ""
with open('/etc/krb5.conf', 'r') as krbconf:
    for line in krbconf.readlines():
        if line.strip().startswith("default_realm"):
            realm_name = line.strip().split("=")[1].strip()

if not realm_name:
    print("Could not detect realm name")
    sys.exit(1)


if(len(sys.argv) < 3):
    print("Expected format: puppet-kerberos-wrapper user command")
    sys.exit(1)

user = sys.argv[1]
cmd = sys.argv[2:]
fqdn = socket.getfqdn()

if not keytabs.get(user, None):
    print("No keytab defined for this user, please review the necessary Kerberos "
          "credentials and amend this script if a new principal is needed.")
    sys.exit(1)

principal = "%s/%s@%s" % (user, fqdn, realm_name)

subprocess.call(["/usr/bin/kinit", principal, "-k", "-t", keytabs[user]])
subprocess.call(cmd)
