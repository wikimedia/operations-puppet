#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import argparse
import sys

import bituldap as ldap


def main():
    parser = argparse.ArgumentParser(
                    prog='modify-mfa',
                    description='Allows the enabling or disabling of MFA for a given user.')

    parser.add_argument('user', help='username of the user to modify')
    enable_group = parser.add_mutually_exclusive_group(required=True)
    enable_group.add_argument('--enable', action='store_true', help='enable MFA')
    enable_group.add_argument('--disable', action='store_true', help='disable MFA.')
    parser.add_argument('--method', default='mfa-u2f', choices=['mfa-u2f', 'mfa-webauthn'])

    args = parser.parse_args()
    user = ldap.get_user(args.user)

    if not user:
        print(f'user {args.user} not found in LDAP.')
        return 1

    if not hasattr(user, 'mfa-method'):
        print('User does not have the mfa-method attribute. '
              'Did you forget to load the wikimediaPerson schema?')
        return 1

    method = '' if args.disable else args.method

    setattr(user, 'mfa-method', method)
    success: bool = user.entry_commit_changes()

    if success:
        if args.disable:
            print(f'successfully disabled mfa method for user: {args.user}')
        else:
            print(f'successfully updated mfa method ({method}) for user: {args.user}')

        return 0

    print(f'failed to update MFA method for user: {args.user}, method: {method}')
    return 1


if __name__ == '__main__':
    sys.exit(main())
