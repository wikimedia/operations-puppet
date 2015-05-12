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
    with open(staging, "r") as dblist:
        for db in dblist:
            db = db.strip()
            f = os.tmpfile()
            cmd = "/usr/local/bin/mwscript update.php --wiki=%s --quick" % db
            p = subprocess.Popen(cmd, stdout=f, stderr=f, shell=True)
            procs.append((p, f, cmd))
            if (len(procs) >= cores):
                do_wait(procs)
                procs = []


def parse_args():
    """
    parse arguments
    """
    ap = argparse.ArgumentParser()
    ap.add_argument("-b", "--batch", required=False,
            help="Number of databases to update in parallel")
    ap.add_argument("-d", "--dblist", required=False,
            help="Path to dblist file")
    return vars(ap.parse_args())


def get_cores(args):
    """
    get number of processes to run in parallel
    """
    cores = args.get("batch")

    if cores is not None:
        return int(cores)

    return max(multiprocessing.cpu_count() / 2, 1)


def get_dblist(args):
    """
    check and return path to dblist
    """
    dblist = args.get("dblist")

    if dblist is None:
        dblist = os.path.join(get_staging_dir(), "all-labs.dblist")

    if not os.path.exists(dblist):
        raise IOError(errno.ENOENT, "Labs dblist not found", dblist)

    return dblist


def main():
    args = parse_args()
    dblist = get_dblist(args)
    cores = get_cores(args)
    run_updates(dblist, cores)

if __name__ == '__main__':
    sys.exit(main())
