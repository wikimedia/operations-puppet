#!/usr/bin/env python
"""
  hhvm_cleanup_cache

  Prune stale tables from the HHVM bytecode cache.
  Tables are deemed unused if they reference a repo schema other than the
  current one.
"""
import sys
import logging
from logging.handlers import SysLogHandler
import os.path
import subprocess
import sqlite3
import argparse

TABLES_QUERY = """
SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE '%{}'
"""


def get_repo_schema():
    """
    Gets the repository schema version from the hhvm admin interface
    """
    return subprocess.check_output(['/usr/bin/hhvm', '--repo-schema']).rstrip()


def delete_and_vacuum(dbh, tables):
    """
    Drops stale tables and vacuums the database
    """
    log = logging.getLogger('cleanup_hhvm_cache')
    cur = dbh.cursor()
    log.info("Deleting tables")
    for table in tables:
        log.debug("Deleting table %s", table)
        cur.execute("DROP TABLE {}".format(table))
    log.info("Vacuuming the db")
    cur.execute("VACUUM")
    log.info("Done")


def setup_logging(debug=False):
    """
    Setting up logging
    """
    log_format = '%(name)s: %(levelname)s - %(message)s'
    log = logging.getLogger('cleanup_hhvm_cache')
    if not debug:
        # if normal mode, log to syslog
        log.setLevel(logging.INFO)
        log.propagate = False
        handler = SysLogHandler(
            address='/dev/log',
            facility=SysLogHandler.LOG_LOCAL3)
        formatter = logging.Formatter(fmt=log_format)
        handler.setFormatter(formatter)
        log.addHandler(handler)
    else:
        # if debug mode, print to stderr
        logging.basicConfig(level=logging.DEBUG, format=log_format)
    return log


def main():
    parser = argparse.ArgumentParser(
        prog="hhvm_cleanup_cache",
        description="Prune unused entries from a HHVM bytecode cache database"
    )
    parser.add_argument('--debug', action='store_true',
                        default=False, help="print debug information to stdout")
    parser.add_argument('--noop', action='store_true', default=False,
                        help="show what would be done, but take no action")
    parser.add_argument('filename',
                        help="the path of the bytecode cache database")

    args = parser.parse_args()
    log = setup_logging(args.debug)
    repo_size_before = os.path.getsize(args.filename)
    try:
        repo_schema = get_repo_schema()
        if not repo_schema:
            log.error("Got an empty schema, cannot continue")
            sys.exit(1)
        else:
            log.info("Current schema version is %s", repo_schema)
            hhvm_db = args.filename
        with sqlite3.connect(hhvm_db) as dbh:
            cursor = dbh.cursor()
            tables_to_clean = [
                t for (t,) in cursor.execute(
                    TABLES_QUERY.format(repo_schema)
                ).fetchall()
            ]
            # To remove the annoying unicode marker
            printable_tables = ", ".join(tables_to_clean)
            if args.noop:
                log.info("Tables to remove: %s", printable_tables)
                log.info("NOT deleting tables (noop)")
            else:
                log.debug("Tables to remove: %s", printable_tables)
                delete_and_vacuum(dbh, tables_to_clean)
        repo_size_after = os.path.getsize(args.filename)
        kb_change = (repo_size_before - repo_size_after) / 1024.0
        log.info('Pruned %.2f kB.', kb_change)
    except Exception as e:
        log.error("Execution failed with error %s", e)
        sys.exit(1)


if __name__ == '__main__':
    main()
