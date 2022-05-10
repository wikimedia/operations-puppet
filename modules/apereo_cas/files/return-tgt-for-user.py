#!/bin/python3
# SPDX-License-Identifier: Apache-2.0

# Return the latest TGT for a user based in audit.log data
# The audit log only contains slightly anonymised TGT lists, but we can
# match it against the current entries in memcached

import argparse
import dateutil.parser
import os
import re
import subprocess
import sys

if os.geteuid() != 0:
    print("Needs to be run as root")
    sys.exit(1)


class User:
    def __init__(self, tgt, creation):
        self.tgt = tgt
        self.date = creation


# This returns neutralised memcached token names, e.g. TGT-4-*****PGuP45c0rQ-idp-test1001
def parse_tgts(filenames):

    record_separator = 61 * "="
    start_element = False
    user = ""
    action = ""
    what = ""
    tgts = {}

    logfiles_processed = 0
    for filename in filenames:
        if os.path.exists(filename):
            logfiles_processed += 1
            with open(filename, "r") as auditlog:
                for line in auditlog.readlines():
                    line = line.strip()
                    if not start_element and line == record_separator:
                        start_element = True

                    if line.startswith("WHO:"):
                        user = line.split()[1]

                    if line.startswith("WHAT:"):
                        what = line.split()[1]

                    if line.startswith("WHEN:"):
                        when = dateutil.parser.parse(line.split(":", 1)[1])

                    if line.startswith("ACTION:"):
                        action = line.split()[1]

                    if start_element and line == record_separator:
                        start_element = False
                        if action != "TICKET_GRANTING_TICKET_CREATED":
                            continue
                        if tgts.get(user, False) and tgts[user].date > when:
                            continue
                        tgts[user] = User(what, when)

    if logfiles_processed == 0:
        print("No cas audit files could be found, bailing out")
        sys.exit(1)

    return tgts


def get_memcached_keys(server):
    memcached_keys = []

    try:
        memcdump = subprocess.run(["/usr/bin/memcdump", "--servers=" + server], capture_output=True)
    except subprocess.CalledProcessError as e:
        print("memcache dump failed: {}".format(e))
        sys.exit(1)

    for memkey in memcdump.stdout.decode("utf-8").split('\n'):
        memcached_keys.append(memkey)

    return memcached_keys


def parse_args():
    parser = argparse.ArgumentParser(
        description='Return the TGT for a logged-in user')
    parser.add_argument('-u', dest='username', required=True,
                        help='The Wikitech username/CN of the user')
    parser.add_argument('-f', dest='filename', required=True, nargs='+',
                        help='The names of CAS audit logfiles, non-existing files are skipped')
    parser.add_argument('-s', dest='server', required=True,
                        help='The name of the memcached server/port, e.g. 127.0.0.1:11000')

    return parser.parse_args()


def main():
    args = parse_args()

    memcached_keys = get_memcached_keys(args.server)
    tgts = parse_tgts(args.filename)
    matched_entry = False
    if args.username not in tgts.keys():
        print("User {} does not have a current session".format(args.username))
        sys.exit(1)
    else:
        start_tgt = tgts[args.username].tgt.split("*****")[0]
        end_tgt = tgts[args.username].tgt.split("*****")[1]

        for key in memcached_keys:
            if re.search("^" + start_tgt + ".*" + end_tgt + "$", key):
                matched_entry = True
                print(key)

    if matched_entry:
        return 0
    else:
        print("Could not match a session for user {}".format(args.username))
        return 1


if __name__ == '__main__':
    sys.exit(main())
