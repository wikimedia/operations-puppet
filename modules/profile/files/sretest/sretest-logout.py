#!/usr/bin/python3
# -*- coding: utf-8 -*-

import argparse
import json
import os
import subprocess
import sys

SERVICE = 'sretest'


# Return codes follow the logout.d semantics, see T283242
def logout(uid, verbose):

    try:
        output = subprocess.check_output(["/usr/bin/loginctl", "terminate-user", uid],
                                         universal_newlines=True).strip()
    except subprocess.CalledProcessError as error:
        print('Failed to logout user {}: {}'.format(uid, error.returncode))
        return 1

    if verbose:
        print(output)
    return 0


# Return codes follow the logout.d semantics, see T283242
def query(uid):
    output = ""

    res = {'id': uid}

    try:
        output = subprocess.check_output(["/usr/bin/loginctl", "--no-pager", "user-status", uid],
                                         universal_newlines=True).strip()
    except subprocess.CalledProcessError as error:
        res['active'] = 'unknown'
        res['verbose'] = error.output
        print(json.dumps(res))
        return 0

    if output:
        res['active'] = "active"
    else:
        res['active'] = "inactive"

    res['verbose'] = output
    print(json.dumps(res))
    return 1


def main():
    if os.geteuid() != 0:
        print("Logout script needs to be run as root")
        sys.exit(1)

    parser = argparse.ArgumentParser()

    parser.add_argument("--verbose", action="store_true", dest="verbose",
                        help="Enable verbose output")

    subp = parser.add_subparsers(title='Command', description='Valid commands', dest='command')
    subp.required = True

    parser_logout = subp.add_parser('logout', help='Logout a user')
    parser_logout.add_argument('--uid',
                               help="Forcibly logout LDAP UID for service {}".
                               format(SERVICE), required=True)
    parser_logout.add_argument('--cn',
                               help="Forcibly logout wikitech name/CN for service {}".
                               format(SERVICE))

    parser_query = subp.add_parser('query', help='Query the login state of a user')
    parser_query.add_argument('--uid',
                              help="Query login state for LDAP UID at service {}".
                              format(SERVICE), required=True)
    parser_query.add_argument('--cn',
                              help="Query login state for wikitech name/CN at service {}".
                              format(SERVICE))

    args = parser.parse_args()
    if args.command == "logout":
        sys.exit(logout(args.uid, args.cn, args.verbose))

    elif args.command == "query":
        sys.exit(query(args.uid, args.cn, args.verbose))


if __name__ == '__main__':
    main()
