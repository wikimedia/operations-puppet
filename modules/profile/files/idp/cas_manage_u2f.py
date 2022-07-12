#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Script to manage Apereo CAS U2F registrations"""

import re
import logging

from argparse import ArgumentParser
from dataclasses import dataclass
from datetime import datetime
from os import getuid
from pathlib import Path
from typing import Dict

import pymysql


LOG = logging.getLogger('cas-manage-u2f')


class UnknownUserError(ValueError):
    """Raised when no users found"""


class TooManyUsersError(ValueError):
    """Raised when no users found"""


@dataclass
class U2FRegistration:
    """Class to hold U2F registrations"""

    id: int  # pylint: disable=invalid-name
    created_Date: datetime  # pylint: disable=invalid-name
    record: str
    username: str

    def __str__(self):
        return '\n'.join(
            [
                f'Username:\t{self.username.decode()}',
                f'Registered:\t{str(self.created_Date)}',
            ]
        )


def get_args():
    """Parse arguments

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(
        '-c', '--config', default='/etc/cas/config/cas.properties', type=Path
    )
    parser.add_argument('--delete', action='store_true')
    parser.add_argument('--force', action='store_true')
    parser.add_argument('-v', '--verbose', action='count')
    parser.add_argument('username')
    return parser.parse_args()


def set_log_level(args_level):
    """Convert an integer to a logging log level

    Arguments:
        args_level (int): The log level as an integer

    """
    level = {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)
    logging.basicConfig(level=level)


def get_db_config(cas_cfg: Path) -> Dict:
    """Parse the cas config path and return a pymysql config dict

    Arguments:
        cas_cfg (Path): The path to the config file

    Returns:
        dict: A dictionary object of DB connections parameters

    """
    maps = {
        'cas.authn.mfa.u2f.jpa.password': 'password',
        'cas.authn.mfa.u2f.jpa.user': 'user',
    }
    config = {
        'cursorclass': pymysql.cursors.DictCursor,
        'charset': 'utf8mb4',
        'ssl': {
            'ca': '/var/lib/puppet/ssl/certs/ca.pem',
            'check_hostname': False,
        },
    }
    uri_pattern = re.compile(r'jdbc:mysql:\/\/(?P<host>[^\/]+)\/(?P<db_name>[^?]+)')
    for line in cas_cfg.read_text().splitlines():
        if '=' not in line:
            continue
        key, value = [x.strip() for x in line.split('=', 1)]
        if key in maps:
            config[maps[key]] = value
            continue
        if key == 'cas.authn.mfa.u2f.jpa.url':
            match = uri_pattern.match(value)
            config['host'] = match['host']
            config['db'] = match['db_name']
            continue
    LOG.debug('DB config: %s', config)
    return config


def get_registration(
    db_conn: pymysql.connections.Connection, username: str
) -> U2FRegistration:
    """Query the mysql database for the current registration

    Arguments:
        db_conn (pymysql.connections.Connection): a connection object to the db
        username (str): The username to query

    Raises:
        UnknownUserError: If no user is found
        TooManyUsersError: If more then one user is found

    Returns:
        U2FRegistration: A object representing the users u2f registration

    """
    sql = 'SELECT * FROM U2FDevice_Registration WHERE `username`=%s'
    with db_conn.cursor() as cursor:
        cursor.execute(sql, (username,))
        if cursor.rowcount > 1:
            raise UnknownUserError(f'Found multiple registrations matching: {username}')
        if cursor.rowcount < 1:
            raise TooManyUsersError(f'Found no registrations matching: {username}')

        registration = U2FRegistration(**cursor.fetchone())
        LOG.debug('Found reg: %s', registration)
        return registration


def delete_registration(
    db_conn: pymysql.connections.Connection, registration: U2FRegistration
):
    """Delete a u2f registration

    Arguments:
        db_conn (pymysql.connections.Connection): a connection object to the db
        username (str): The username to query
        registration (U2FRegistration): A object representing the users u2f registration

    """
    sql = 'DELETE FROM U2FDevice_Registration WHERE `username`=%s'
    LOG.debug('Deleting: %s', registration.username.decode())
    with db_conn.cursor() as cursor:
        # We can safely just use the username here as we make sure
        # there is only one match earlier in the code
        cursor.execute(sql, (registration.username.decode(),))
        LOG.info('Registration Deleted: %s', registration.username.decode())
    db_conn.commit()


def main():
    """main entry point

    Returns:
        int: an int representing the exit code
    """

    if getuid() != 0:
        LOG.error('Script requires root to run')
        return 1
    args = get_args()
    set_log_level(args.verbose)
    db_conn = pymysql.connect(**get_db_config(args.config))
    try:
        registration = get_registration(db_conn, args.username)
    except TooManyUsersError as error:
        LOG.error(error)
        return 1
    except UnknownUserError as error:
        LOG.warning(error)
        return 0
    print(registration)
    if args.delete:
        if not args.force:
            answer = input(
                f'Type "yes" to confirm the deletion of {registration.username} displayed above\n> '
            )
            if answer != 'yes':
                LOG.error('Aborting delete for %s', registration.username)
                return 1
        delete_registration(db_conn, registration)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
