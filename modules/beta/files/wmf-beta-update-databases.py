#!/usr/bin/env python3
#######################################################################
# WARNING: this file is managed by Puppet
# puppet:///modules/beta/wmf-beta-update-databases.py
#######################################################################

"""
Run update.php for all dbs listed in a dblist
"""
import argparse
import errno
import os
import shlex
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed


def get_staging_dir():
    return os.getenv("MEDIAWIKI_STAGING_DIR", "/srv/mediawiki-staging")


def get_default_dblist():
    return os.path.join(get_staging_dir(), 'dblists', 'all-labs.dblist')


def ignore_comments_and_emptylines(lines):
    """
    Given an array of provided file lines, clean up comments and
    empty lines as defined by:
    <https://gerrit.wikimedia.org/r/plugins/gitiles/operations/
    mediawiki-config/+/master/multiversion/MWWikiversions.php#77>
    """
    dbs = list()
    for line in lines:
        # Strip comments ('#' to end-of-line) and trim whitespace.
        db = line.split('#')[0].strip()
        if db.startswith('%%'):
            raise Exception('Encountered dblist expression inside dblist list file.')
        elif db != '':
            dbs.append(db)
    return dbs


def run_one_update(db):
    """
    Worker: run update.php for a single wiki and return
    (db, exit_code, combined_output, cmd). cmd is the argv list, returned so
    the parent can show the exact failing command.
    """
    cmd = [
        "/usr/local/bin/mwscript", "update.php",
        f"--wiki={db}", "--doshared", "--quick", "--skip-config-validation",
    ]
    try:
        proc = subprocess.run(
            cmd,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
        )
    except OSError as e:
        return (db, 1, f"failed to launch update.php for {db}: {e}", cmd)
    return (db, proc.returncode, (proc.stdout or "").strip(), cmd)


def run_updates(staging, cores):
    """
    Run update.php on each wiki listed in the dblist, updating up to `cores`
    wikis at a time. Fails fast: if any wiki's update fails, stop and exit
    non-zero.
    """
    with open(staging, "r") as dblist:
        dbs = ignore_comments_and_emptylines(dblist)

    num_dbs = len(dbs)
    print(f"Running update.php for {num_dbs} wikis.")
    saw_failure = False
    with ThreadPoolExecutor(max_workers=cores) as executor:
        futures = {executor.submit(run_one_update, db): db for db in dbs}
        try:
            for future in as_completed(futures):
                db, exit_code, output, cmd = future.result()
                if output:
                    prefix = f"{db} | "
                    print("\n".join(prefix + line for line in output.splitlines()))
                if exit_code != 0:
                    print(f"Command failed (exit {exit_code}): {shlex.join(cmd)}")
                    saw_failure = True
                    break
        finally:
            if saw_failure:
                for f in futures:
                    f.cancel()

    if saw_failure:
        raise SystemExit(1)

    print(f"Updated {num_dbs} wikis.")


def parse_args():
    """
    parse arguments
    """
    ap = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    ap.add_argument("-b", "--batch", required=False, type=int,
                    default=os.cpu_count() or 1,
                    help="Number of databases to update in parallel")
    ap.add_argument("-d", "--dblist", required=False,
                    default=get_default_dblist(), help="Path to dblist file")

    return ap.parse_args()


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
