#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import sys
import socket
import subprocess
import logging
import logging.handlers
import os


logger = logging.getLogger('kerberos-run-command')
logger.setLevel(logging.INFO)
handler = logging.handlers.SysLogHandler('/dev/log')
formatter = logging.Formatter('%(name)s - %(message)s')
logger.addHandler(handler)

# Keytabs with special paths
keytabs = {
    'hdfs': '/etc/security/keytabs/hadoop/hdfs.keytab',
    'yarn': '/etc/security/keytabs/hadoop/yarn.keytab',
    'oozie': '/etc/security/keytabs/oozie/HTTP-oozie.keytab',
}


def get_username():
    """Detect and return the name of the effective running user even if run as root.
    Returns:
        The name of the effective running user or ``-`` if unable to detect it.
    """
    user = os.getenv('USER')
    sudo_user = os.getenv('SUDO_USER')
    if sudo_user is not None and sudo_user != 'root':
        return sudo_user
    if user is not None:
        return user
    return '-'


def main():
    realm_name = ""
    with open('/etc/krb5.conf', 'r') as krbconf:
        for line in krbconf.readlines():
            if line.strip().startswith("default_realm"):
                realm_name = line.strip().split("=")[1].strip()

    if not realm_name:
        print("Could not detect realm name, aborting...")
        sys.exit(1)

    if len(sys.argv) < 3:
        print("Expected format: kerberos-run-command user command")
        sys.exit(1)

    running_user = get_username()

    run_as_user = sys.argv[1]
    cmd = sys.argv[2:]
    fqdn = socket.getfqdn()

    if not keytabs.get(run_as_user, None):
        keytab_path = "/etc/security/keytabs/{}/{}.keytab".format(run_as_user, run_as_user)
    else:
        keytab_path = keytabs[run_as_user]

    if not os.path.isfile(keytab_path):
        print("The user keytab that you are trying to use "
              "({}) doesn't exist or it isn't readable from your "
              "user, aborting...".format(keytab_path))
        sys.exit(1)

    principal = "%s/%s@%s" % (run_as_user, fqdn, realm_name)

    logger.info(
        "kerberos-run-command: User {} executes as user {} the command {}"
        .format(running_user, run_as_user, cmd))

    subprocess.call(["/usr/bin/kinit", principal, "-k", "-t", keytab_path])
    sys.exit(subprocess.call(cmd))


if __name__ == '__main__':
    main()
