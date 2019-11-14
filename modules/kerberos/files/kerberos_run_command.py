#!/usr/bin/env python3

import sys
import socket
import subprocess
import os

# Keytabs with special paths
keytabs = {
    'hdfs': '/etc/security/keytabs/hadoop/hdfs.keytab',
    'yarn': '/etc/security/keytabs/hadoop/yarn.keytab',
    'oozie': '/etc/security/keytabs/oozie/HTTP-oozie.keytab',
}

realm_name = ""
with open('/etc/krb5.conf', 'r') as krbconf:
    for line in krbconf.readlines():
        if line.strip().startswith("default_realm"):
            realm_name = line.strip().split("=")[1].strip()

if not realm_name:
    print("Could not detect realm name, aborting...")
    sys.exit(1)


if(len(sys.argv) < 3):
    print("Expected format: kerberos-run-command user command")
    sys.exit(1)

user = sys.argv[1]
cmd = sys.argv[2:]
fqdn = socket.getfqdn()

if not keytabs.get(user, None):
    keytab_path = "/etc/security/keytabs/{}/{}.keytab".format(user, user)
else:
    keytab_path = keytabs[user]

if not os.path.isfile(keytab_path):
    print("The user keytab that you are trying to use "
          "({}) doesn't exist or it isn't readable from your "
          "user, aborting...".format(keytab_path))
    sys.exit(1)

principal = "%s/%s@%s" % (user, fqdn, realm_name)

subprocess.call(["/usr/bin/kinit", principal, "-k", "-t", keytab_path])
subprocess.call(cmd)
