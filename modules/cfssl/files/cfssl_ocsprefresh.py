#!/usr/bin/env python3
"""Script used to refresh the ocsp database and regenerate the ocsp responses"""
import json
import logging
import pymysql
import re
import shlex

from argparse import ArgumentParser
from configparser import ConfigParser
from datetime import datetime
from pathlib import Path
from socket import getfqdn, gethostbyname_ex
from subprocess import CalledProcessError, check_call, check_output


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-v', '--verbose', action='count')
    parser.add_argument('-c', '--config', default='/etc/cfssl/multiroot.conf')
    parser.add_argument('--cname', required=True)
    parser.add_argument('--ca-file', required=True)
    parser.add_argument('--responder-cert', required=True)
    parser.add_argument('--responder-key', required=True)
    parser.add_argument('--responses-file', required=True)
    parser.add_argument('--restart-service', required=True)
    parser.add_argument('signer', help='CA Signer label')
    return parser.parse_args()


def get_log_level(args_level):
    """Configure logging"""
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
    """Call cfssl ocspdump and indicate if there is new data return true

    Parameters:
        dbconfig (str):       path to the dbconfig
        responses_file (str): path to the responder public certificate

    Returns:
        bool: indicate if the ocspresponse file has been updated
    """
    command = f"/usr/bin/cfssl ocspdump -db-config {dbconfig}"
    logging.debug('running %s', command)
    responses = check_output(shlex.split(command))
    logging.debug('read current responses file: %s', responses_file)
    # TODO: this is false on every run as we re-sign each time
    try:
        if responses == responses_file.read_bytes():
            logging.debug('No update required')
            return False
    except FileNotFoundError:
        logging.warning('No current responses file')
        pass
    logging.debug('Updating response file: %s', responses_file)
    responses_file.write_bytes(responses)
    return True


def get_db_connection(dbconfig):
    config = json.loads(Path(dbconfig).read_bytes())
    pattern = re.compile(
        r'(?P<user>[^:]+):(?P<pass>[^@]+)@tcp\((?P<host>[^:]+):(?P<port>\d+)\)\/(?P<db>[^\?]+)')
    match = pattern.search(config['data_source'])
    ssl = {'ca': '/etc/ssl/certs/Puppet_Internal_CA.pem', 'check_hostname': False}
    return (pymysql.connect(host=match['host'],
                            port=int(match['port']),
                            user=match['user'],
                            password=match['pass'],
                            db=match['db'],
                            charset="utf8mb4",
                            ssl=ssl),
            match['db'])


def get_db_update_time(db_conn, db_name, table_name):
    sql = 'SELECT `UPDATE_TIME` FROM tables WHERE `TABLE_SCHEMA` = %s AND `TABLE_NAME` = %s'
    with db_conn.cursor() as cursor:
        cursor.execute(sql, (db_name, table_name))
        result = cursor.fetchone()
        logging.debug('%s.%s last updated: %s', db_name, table_name, result[0])
        return result[0]


def update_required(responses_file: Path, dbconfig: str, primary: bool) -> bool:
    """Check if we need to regenerate the responses file.  On the primary server we should check
    the certificates table to see if there re any new certificates.  otherwise we should check the
    ocsp responses table to see if something else has update the table

    Arguments:
        response_file (`pathlib.Path`): path to the responses file
        dbconfig (`pathlib.Path`): path to the db config file
        primary (bool): indicate if this is the primary server

    Returns:
        bool: indicate if an update is required
    """
    # If the responses file dosen't exist then update
    if not responses_file.exists():
        return True
    table_name = 'certificates' if primary else 'ocsp_responses'
    responses_meta = responses_file.stat()
    last_update = datetime.fromtimestamp(responses_meta.st_mtime)
    logging.debug('%s last updated: %s', responses_file, last_update)
    (db_conn, db_name) = get_db_connection(dbconfig)
    try:
        return last_update < get_db_update_time(dbconfig, db_name, table_name)
    finally:
        db_conn.close()


def is_primary(cname: str) -> bool:
    """query the cname record to see if it currently points to the cutrrent host
    if so this is the primary server

    Arguments:
        cname (str): The CNAME record to check

    Returns
        bool: indicate if this is the current primary server"""
    return getfqdn() == gethostbyname_ex(cname)[0]


def main():
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))

    config = ConfigParser()
    config.read(args.config)

    responses_file = Path(args.responses_file)
    primary = is_primary(args.cname)

    if args.signer not in config.sections():
        logging.error('%s is not a configured signer', args.signer)
        return 1
    try:
        dbconfig = config[args.signer]['dbconfig']
        if not update_required(responses_file, dbconfig, primary):
            logging.debug('%s: no update required', args.signer)
            return 0
    except KeyError:
        logging.error('%s unable to find dbconfig', args.signer)
        return 1

    if primary:
        # only regenerate the responses if we are on the primary
        try:
            ocsprefresh(dbconfig, args.responder_cert, args.responder_key, args.ca_file)
        except CalledProcessError as error:
            logging.error('ocsprefresh failed: %s', error)
            return 1
    try:
        if ocspdump(dbconfig, responses_file):
            check_call(shlex.split(f"/usr/bin/systemctl restart {args.restart_service}"))
    except CalledProcessError as error:
        logging.error('ocspdump failed: %s', error)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
