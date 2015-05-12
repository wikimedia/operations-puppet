#!/usr/bin/env python
#######################################################################
# WARNING: this file is managed by Puppet
# puppet:///modules/beta/wmf-beta-update-databases.py
#######################################################################

"""
Updates update.php on all dbs listed in all-labs.dblist
"""
import os
import sys
import errno
import multiprocessing
import subprocess

import time

def get_staging_dir():
    return os.getenv("MEDIAWIKI_STAGING_DIR", "/srv/mediawiki-staging")

def do_wait(procs):
    """
    wait for command in procs array to execute, dump their output
    """
    for p, f, cmd in procs:
        if p.wait() > 0:
            raise Exception("command: ", cmd, "output: ", f.read())
        f.seek(0)
        print f.read().strip()
        f.close()

def run_updates(staging, cores):
    """
    run update.php on each wiki found in all-labs.dblist
    """
    procs = []
    with open(staging, 'r') as dblist:
        for db in dblist:
            db = db.strip()
            f = os.tmpfile()
            cmd = '/usr/local/bin/mwscript update.php --wiki=%s --quick' % db
            p = subprocess.Popen(cmd, stdout=f, stderr=f, shell=True)
            procs.append((p, f, cmd))
            if (len(procs) >= cores):
                do_wait(procs)
                procs = []

def main():
    staging = os.path.join(get_staging_dir(), 'all-labs.dblist')
    if not os.path.exists(staging):
        raise IOError(errno.ENOENT, 'Labs dblist not found', staging)

    cores = max(multiprocessing.cpu_count() / 2, 1)
    run_updates(staging, cores)

if __name__ == '__main__':
    sys.exit(main())
