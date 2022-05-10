#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import sys
import memcache
import os
import pickle
import subprocess
import argparse


if os.geteuid() != 0:
    print("Needs to be run as root")
    sys.exit(1)


def dump():
    try:
        memcdump = subprocess.run(["/usr/bin/memcdump", "--servers=" + server], capture_output=True)
    except subprocess.CalledProcessError as e:
        print("memcache dump failed: {}".format(e))
        sys.exit(1)

    elements = {}
    for memkey in memcdump.stdout.decode("utf-8").split('\n'):
        if memkey:
            elements[memkey] = connection.get(memkey)

    with open(args.dumpfile, "wb") as dumpfd:
        pickle.dump(elements, dumpfd)


def restore():
    with open(args.dumpfile, "rb") as dumpfd:
        elements = pickle.load(dumpfd)

    [connection.set(k, v) for k, v in elements.items()]


parser = argparse.ArgumentParser()
parser.add_argument('mode', help='Either dump or restore')
parser.add_argument('-f', '--dumpfile', required=True,
                    help='The file to read the memcached content from')
args = parser.parse_args()


server = "127.0.0.1:11000"
connection = memcache.Client([server])

if args.mode == 'dump':
    dump()
elif args.mode == 'restore':
    restore()
else:
    print("Invalid mode; either dump or restore")
    sys.exit(1)
