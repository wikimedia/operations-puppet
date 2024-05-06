#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
#
# Confd attempts to replace each file atomically and
# can abort for safety reasons if a specified check script
# exits > 0.  This lint also passes silently without running
# Confd in the console.  This wrapper runs the lint itself
# logging error output as appropriate and managing the state of
# a runtime error file for alerting. Output to stderror from
# the check script will be logged and the exit code passed up.
#
# * Confd is typically deployed with the watch keyword and as such
#   will only seek to lint and modify files irregularly.  This does
#   not lend itself well to nsca.
#
import argparse
import sys
import subprocess
import time
import os
from os import path
from syslog import syslog

error_dir = '/var/run/confd-template'


def touch(fname, times=None):
    log("updating error mtime on %s" % (fname,))
    with open(fname, 'w+'):
        os.utime(fname, None)


def log(msg):
    print(msg)
    syslog(msg)


def main():
    parser = argparse.ArgumentParser()
    # TODO: T363924 make resource required and clean up conditional logic below
    # once puppet is updated.
    parser.add_argument(
        '--resource',
        help=(
            'A unique file-safe identifier of the confd resource associated '
            'with this check (i.e., the stem of the template name). Used to '
            'construct the error state file name.'
        ),
    )
    parser.add_argument(
        'check',
        nargs='+',
        type=str,
        help='The check command to execute.',
    )
    args = parser.parse_args()

    if not os.path.exists(error_dir):
        os.makedirs(error_dir)

    target = args.check
    if args.resource is None:
        error_file_base = path.basename(target[-1])
    else:
        error_file_base = args.resource
    error_file = path.join(error_dir, f"{error_file_base}.err")

    start = time.time()
    p = subprocess.Popen(target,
                         shell=False,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE,
                         universal_newlines=True)
    out, err = p.communicate()
    retcode = p.wait()
    duration = time.time() - start

    if not retcode and retcode != 0:
        retcode = 3

    msg = "linting '%s' with %s (%ss)" % (' '.join(target),
                                          retcode,
                                          duration)

    if retcode:
        error = 'failed %s %s' % (msg, err)
        touch(error_file)
        log(error)
        sys.exit(int(retcode))
    else:
        if os.path.exists(error_file):
            os.remove(error_file)
            print(msg)
        sys.exit(0)


if __name__ == "__main__":
    main()
