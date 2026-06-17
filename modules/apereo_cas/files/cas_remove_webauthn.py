#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0
"""Inspect and update CAS WebAuthN registrations."""

import logging
import re

from argparse import ArgumentParser
from dataclasses import asdict, dataclass
from configparser import ConfigParser
from contextlib import contextmanager
from pathlib import Path
from typing import Dict

from pymysql.connections import Connection
from wmflib.interactive import ask_confirmation, AbortError


@dataclass
class DBConfig:
    """dataclass for the db server"""

    host: str
    password: str
    user: str
    database: str
    charset: str = 'utf8mb4'

    @contextmanager
    def connection(self):
        """Context-manager for a mysql connection to remote host"""
        conn = Connection(**asdict(self))
        try:
            yield conn
        finally:
            conn.close()


def get_args() -> None:
    """Parse arguments.

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(
        '-c',
        '--config',
        default='/etc/cas/config/cas.properties',
        type=Path,
        help="The cas config file",
    )
    parser.add_argument(
        '-v',
        '--verbose',
        action='count',
        default=0,
        help="Increase verbosity, pass multiple times for additional levels",
    )
    parser.add_argument(
        '--force',
        action='store_true',
        help="Don't prompt the user for confirmation before deleting the registration",
    )
    parser.add_argument('username', help="The user to act on")
    return parser.parse_args()


def get_log_level(args_level: int) -> int:
    """Convert an integer to a logging log level.

    Arguments:
        args_level (int): The log level as an integer

    Returns:
        int: the logging loglevel
    """
    return {
        0: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


def read_config(config: Path) -> Dict:
    """Read a config file and return the config as a dictionary"""
    cfg = ConfigParser()
    cfg.read_string("[dummy]\n" + config.read_text())
    return cfg['dummy']


def get_dbconfig(config: Path) -> DBConfig:
    """Parse the config file for the database config"""
    _config = read_config(config)
    username = _config.get('cas.authn.mfa.web-authn.jpa.user')
    password = _config.get('cas.authn.mfa.web-authn.jpa.password')
    url = _config.get('cas.authn.mfa.web-authn.jpa.url')
    host_matcher = re.compile(
        r'^jdbc:mariadb:\/\/(?P<hostname>[^\/]+)\/(?P<database>[^\?]+)'
    )
    match = host_matcher.search(url)
    return DBConfig(match['hostname'], password, username, match['database'])


def main() -> int:
    """Main entry point.

    Returns:
        int: an int representing the exit code
    """
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    delete_sql = "DELETE FROM cas_staging.Jpa_Web_Authn_Credential_Registration where username = %s"
    select_sql = """SELECT * FROM cas_staging.Jpa_Web_Authn_Credential_Registration
                    where username = %s"""
    try:
        dbconfig = get_dbconfig(args.config)
        with dbconfig.connection() as conn:
            with conn.cursor() as cursor:
                if not args.force:
                    cursor.execute(select_sql, (args.username,))
                    rows = cursor.fetchall()
                    if not rows:
                        print(f'No records found for {args.username}')
                        return 0
                    print('The following records will be deleted')
                    for row in rows:
                        # Don't print the entire encrypted blob from the database. Users can't
                        # read it and it looks confusing in the terminal.
                        print(f"'({row[0]}', '{row[1][:20]} ... {row[1][-20:]}', {row[2]})")
                    ask_confirmation('Please confirm you are happy to continue')
                result = cursor.execute(delete_sql, (args.username,))
                logging.info("%d rows deleted", result)
            conn.commit()
    except IOError as err:
        logging.error("Failed to open %s: %s", args.config, err)
        return 1
    except AbortError:
        logging.error("Operation aborted")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
