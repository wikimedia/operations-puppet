#!/usr/bin/python3
import argparse
import os
import subprocess
import sys


def check_role(node, expected_role):
    """
    Check if the role of the DRBD node matches the expected role
    :param expected_role: string
    :returns: boolean
    """
    drbd_res_roles = str(
        subprocess.check_output(['/sbin/drbdadm', 'role', 'all']), 'utf-8')\
        .rstrip('\n').split('\n')

    role_ok = all([role.split('/')[0].lower() == expected_role.lower()
                  for role in drbd_res_roles])

    if not role_ok:
        print('{}: Unexpected role match, expected role {}'.format(
            node, expected_role))

    return role_ok


def main():
    if not os.geteuid() == 0:
        print('Script not run as root')
        sys.exit(1)

    parser = argparse.ArgumentParser('Check DRBD node role')
    parser.add_argument('node', help='Hostname of node being checked')
    parser.add_argument('role', help='Expected drbd role, primary|secondary')
    args = parser.parse_args()

    if not check_role(args.node, args.role):
        sys.exit(1)

    print('DRBD role OK')


if __name__ == '__main__':
    main()
