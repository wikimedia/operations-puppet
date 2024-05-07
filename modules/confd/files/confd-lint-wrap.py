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
from pathlib import Path
from syslog import syslog

ERROR_STATE_PATH = "/var/run/confd-template"


def log(msg):
    print(msg)
    syslog(msg)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--resource',
        required=True,
        help=(
            "A unique file-safe identifier of the confd resource associated "
            "with this check (i.e., the stem of the template name). Used to "
            "construct the error state file name."
        ),
    )
    parser.add_argument(
        "check",
        nargs="+",
        type=str,
        help="The check command to execute.",
    )
    args = parser.parse_args()

    error_dir = Path(ERROR_STATE_PATH)
    if not error_dir.exists():
        error_dir.mkdir(parents=True)

    target = args.check

    error_file = error_dir / f"{args.resource}.err"

    start = time.time()
    p = subprocess.Popen(
        target,
        shell=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
    )
    out, err = p.communicate()
    retcode = p.wait()
    duration = time.time() - start

    if not retcode and retcode != 0:
        retcode = 3

    msg = "linting '%s' with %s (%ss)" % (" ".join(target), retcode, duration)

    if retcode:
        log("failed %s %s" % (msg, err))
        log("updating error mtime on %s" % (error_file))
        error_file.touch()
        sys.exit(int(retcode))
    else:
        if error_file.exists():
            error_file.unlink()
            print(msg)
        sys.exit(0)


if __name__ == "__main__":
    main()
