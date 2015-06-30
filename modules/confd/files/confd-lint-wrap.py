#!/usr/bin/python
#
# Confd attempts to replace each file atomically and
# can abort for safety reasons if a specified check script
# exits > 0.  This lint passes silently without running
# Confd in the console.  This wrapper runs the lint itself
# logging error output as appropriate and manages state for
# a runtime error file for monitoring. Output to stderr from
# the check script will be logged and the exit code passed up.
#
# * Confd is typically deployed with the watch keyword and as such
#   will only seek to lint and modify files irregularly.  This does
#   not lend itself well to nsca.
#
# * A global linting error is surfaced and not per template
#

import sys
import subprocess
import time
import os
from os import path
from datetime import datetime
from syslog import syslog

error_file = '/var/run/confd_template_lint.err'


def touch(fname, times=None):
    log("updating error mtime on %s" % (fname,))
    with open(fname, 'w+'):
        os.utime(fname, None)


def log(msg):
    print msg
    syslog(msg)


def main():

    target = sys.argv[1:]
    start = time.time()
    p = subprocess.Popen(target,
                         shell=False,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
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
            print msg
        sys.exit(0)

if __name__ == "__main__":
    main()
