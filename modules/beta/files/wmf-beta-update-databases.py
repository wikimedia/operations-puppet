#!/usr/bin/env python
#######################################################################
# WARNING: this file is managed by Puppet
# puppet:///modules/beta/wmf-beta-update-databases.py
#######################################################################

"""
Run update.php for all dbs listed in a dblist
"""
import os
import sys
import errno
import multiprocessing
import subprocess
import argparse


def get_staging_dir():
    return os.getenv("MEDIAWIKI_STAGING_DIR", "/srv/mediawiki-staging")


def get_default_dblist():
    return os.path.join(get_staging_dir(), 'dblists', 'all-labs.dblist')


def do_wait(procs):
    """
    wait for command in procs array to execute, dump their output
    """
    for p, cmd in procs:
        (out, stderr_unused) = p.communicate()
        if p.returncode:
            raise Exception("command: ", cmd, "output:", out)


def run_updates(staging, cores):
    """
    run update.php on each wiki found in dblist
    """
    procs = []
    with open(staging, "r") as dblist:
        for db in dblist:
            db = db.strip()
            cmd = "/usr/local/bin/mwscript update.php --wiki=%s --quick" % db
            p = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, shell=True)
            procs.append((p, cmd))
            if (len(procs) >= cores):
                do_wait(procs)
                procs = []

        # catches odd cases where dblist file is smaller than batch size
        if (len(procs) > 0):
            do_wait(procs)


def parse_args():
    """
    parse arguments
    """
    ap = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    ap.add_argument("-b", "--batch", required=False, type=int,
                    default=get_cores(),
                    help="Number of databases to update in parallel")
    ap.add_argument("-d", "--dblist", required=False,
                    default=get_default_dblist(), help="Path to dblist file")

    return ap.parse_args()


def get_cores():
    """
    max of 1/2 cpu_count or 1
    """
    return max(multiprocessing.cpu_count() / 2, 1)


def check_dblist(dblist):
    """
    check and return path to dblist
    """
    if not os.path.exists(dblist):
        raise IOError(errno.ENOENT, "Labs dblist not found", dblist)

    return dblist


def main():
    args = parse_args()
    dblist = check_dblist(args.dblist)
    run_updates(dblist, args.batch)

if __name__ == '__main__':
    sys.exit(main())
