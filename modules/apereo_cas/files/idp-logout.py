#!/usr/bin/python3
# -*- coding: utf-8 -*-

import argparse
import json
import os
import subprocess
import sys
import datetime
import glob
import requests
import configparser

SERVICE = 'idp'


class Tgt:
    def __init__(self, exists, tgt):
        self.exists = exists
        self.tgt = tgt


def query_tgt(cn):

    memcached_host = 'localhost:11000'
    max_tgt_lifetime = 7  # Max ticket lifetime is seven days
    logfile_globbing = '/var/log/cas/cas_audit*log'
    logs_processed = 0
    base_cmd = ['/usr/local/sbin/return-tgt-for-user', '-u', cn, '-s', memcached_host, '-f']

    max_log_age = datetime.datetime.now() - datetime.timedelta(days=max_tgt_lifetime)
    for f in glob.glob(logfile_globbing):
        logs_processed += 1
        if (datetime.datetime.fromtimestamp(os.path.getmtime(f)) > max_log_age):
            base_cmd.append(f)

    if not logs_processed:
        return Tgt(False, "")
    else:
        try:
            output = subprocess.check_output(base_cmd, universal_newlines=True).strip()
        except subprocess.CalledProcessError:
            return Tgt(False, "")

    return Tgt(True, output)


# Return codes follow the logout.d semantics, see T283242
def logout(cn, verbose):

    try:
        cfg = configparser.ConfigParser()
        # The cas.properties is not a standard .ini file to prepend a dummy section
        with open("/etc/cas/config/cas.properties") as stream:
            cfg.read_string("[dummy]\n" + stream.read())
            idp_prefix = cfg.get("dummy", "cas.server.prefix")

    except IOError as e:
        print("Failed to open cas.properties file: {}".format(e))
        return 1

    tgt = query_tgt(cn)
    url = "{}api/ssoSessions/{}".format(idp_prefix, tgt.tgt)

    response = requests.delete(url)

    if response.status_code == 200:
        if tgt.tgt:
            returned_tgt = response.json()['ticketGrantingTicket']
            if tgt.tgt != returned_tgt:
                print("Something went wrong, the terminated TGT doesn't match the requested one")
                return 1

        if verbose:
            if tgt.tgt:
                print("User {} has been logged off and TGT {} was invalidated".
                      format(cn, tgt.tgt))
            else:
                print("No TGT for user {} existed, they were probably already logged out".
                      format(cn))
        return 0
    else:
        return 1


# Return codes follow the logout.d semantics, see T283242
def query(cn):
    res = {}
    res['id'] = cn
    # TODO if verbose is enabled we could print since when a user is logged in
    res['verbose'] = ''

    tgt = query_tgt(cn)

    if tgt.exists:
        res['active'] = "active"
        print(json.dumps(res))
        return 1
    else:
        res['active'] = "inactive"
        print(json.dumps(res))
        return 0


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
                               format(SERVICE))
    parser_logout.add_argument('--cn',
                               help="Forcibly logout wikitech name/CN for service {}".
                               format(SERVICE), required=True)

    parser_query = subp.add_parser('query', help='Query the login state of a user')
    parser_query.add_argument('--uid',
                              help="Query login state for LDAP UID at service {}".
                              format(SERVICE))
    parser_query.add_argument('--cn',
                              help="Query login state for wikitech name/CN at service {}".
                              format(SERVICE), required=True)

    args = parser.parse_args()
    if args.command == "logout":
        sys.exit(logout(args.cn, args.verbose))

    elif args.command == "query":
        sys.exit(query(args.cn))


if __name__ == '__main__':
    main()
