#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Script used to refresh the ocsp database and regenerate the ocsp responses
This script will regenerate the OCSP responses for a specific CA if any CA has
issued a new certificate.  This means that there will be spurious updates however
for now this is an acceptable trade off.

"""
import json
import logging
import shlex

from argparse import ArgumentParser
from datetime import datetime
from pathlib import Path
from subprocess import CalledProcessError, check_call, check_output

import pymysql


def get_args():
    """Parse arguments

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-v', '--verbose', action='count')
    parser.add_argument('-d', '--dbconfig', default='/etc/cfssl/db.conf', type=Path)
    parser.add_argument('--update', action='store_true')
    parser.add_argument('--ca-file', required=True)
    parser.add_argument('--responder-cert', required=True)
    parser.add_argument('--responder-key', required=True)
    parser.add_argument('--responses-file', required=True)
    parser.add_argument('--restart-service', required=True)
    parser.add_argument('signer', help='CA Signer label')
    return parser.parse_args()


def get_log_level(args_level):
    """Convert an integer to a logging log level

    Parameters:
        args_level (int): The log level as an integer

    Returns:
        `logging.loglevel`: the logging loglevel
    """
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG}.get(args_level, logging.DEBUG)


def ocsprefresh(dbconfig, responder_cert, responder_key, ca_file):
    """Call cfssl ocsprefresh with the correct config

    Parameters:
        dbconfig (str):       path to the dbconfig
        responder_cert (str): path to the responder public certificate
        responder_key (str):  path to the responder private key
        ca_file (str):        path to the ca_file
    """
    command = (f"/usr/bin/cfssl ocsprefresh -db-config {dbconfig} "
               f"-responder {responder_cert} -responder-key {responder_key} "
               f"-ca {ca_file}")
    logging.debug('running %s', command)
    check_call(shlex.split(command))


def ocspdump(dbconfig, responses_file):
    """Call cfssl ocspdump with correct parameters

    Parameters:
        dbconfig (str):       path to the dbconfig
        responses_file (str): path to the responder public certificate

    """
    command = f"/usr/bin/cfssl ocspdump -db-config {dbconfig}"
    logging.debug('running %s', command)
    responses = check_output(shlex.split(command))
    logging.debug('Updating response file: %s', responses_file)
    responses_file.write_bytes(responses)


def get_db_update_time(db_conn, db_name, table_name):
    """Select the last update time of a `db_name.table_name`

    Paramters:
        db_conn (`pymysql.connections.Connection`): A pymysql connection
        db_name (str): The database name to query
        db_table (str): The database name to query

    Returns
        `datetime.datetime`: The date of the last update
    """
    sql = ('SELECT `UPDATE_TIME` FROM information_schema.tables '
           'WHERE `TABLE_SCHEMA` = %s AND `TABLE_NAME` = %s')
    with db_conn.cursor() as cursor:
        cursor.execute(sql, (db_name, table_name))
        result = cursor.fetchone()
        logging.debug('%s.%s last updated: %s', db_name, table_name, result[0])
        return result[0]


def update_required(responses_file: Path, dbconfig: Path, update: bool) -> bool:
    """Check if we need to regenerate the responses file.

    If update is true we should check the certificates table to see if there
    are any new certificates.  otherwise we should check the ocsp responses
    table to see if there has been an update

    Arguments:
        response_file (`pathlib.Path`): path to the responses file
        dbconfig (`pathlib.Path`): path to the db config file
        update (bool): indicate if we should make updates

    Returns:
        bool: indicate if an update is required
    """
    # If the responses file dosen't exist then update
    if not responses_file.exists():
        return True
    table_name = 'certificates' if update else 'ocsp_responses'
    responses_meta = responses_file.stat()
    last_update = datetime.fromtimestamp(responses_meta.st_mtime)
    logging.debug('%s last updated: %s', responses_file, last_update)

    config = json.loads(dbconfig.read_bytes())
    db_conn = pymysql.connect(**config)
    try:
        return last_update < get_db_update_time(db_conn, config['db'], table_name)
    finally:
        db_conn.close()


# pylint: disable=R0911
def main():
    """main entry point

    Returns:
        int: an int representing the exit code
    """
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))

    responses_file = Path(args.responses_file)

    try:
        if not update_required(responses_file, Path(f'{args.dbconfig}.json'), args.update):
            logging.debug('%s: no update required', args.signer)
            return 0
    except pymysql.Error as error:
        logging.error('%s issue with SQL query: %s', args.signer, error)
        return 1

    if args.update:
        # only regenerate the responses if we are on the primary
        try:
            ocsprefresh(args.dbconfig, args.responder_cert, args.responder_key, args.ca_file)
        except CalledProcessError as error:
            logging.error('ocsprefresh failed: %s', error)
            return 1
    try:
        ocspdump(args.dbconfig, responses_file)
        check_call(shlex.split(f"/usr/bin/systemctl restart {args.restart_service}"))
    except CalledProcessError as error:
        logging.error('ocspdump failed: %s', error)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
