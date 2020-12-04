#!/usr/bin/env python3
"""Script used to refresh the ocsp database and regenerate the ocsp responses"""
import logging
import shlex

from argparse import ArgumentParser
from configparser import ConfigParser
from pathlib import Path
from subprocess import CalledProcessError, check_call, check_output


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-v', '--verbose', action='count')
    parser.add_argument('-c', '--config', default='/etc/cfssl/multiroot.conf')
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
    command = (f"'/usr/bin/cfssl ocsprefresh -db_config {dbconfig}"
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
    responses_file = Path(responses_file)
    command = f"'/usr/bin/cfssl ocspdump -db_config {dbconfig}"
    logging.debug('running %s', command)
    responses = check_output(shlex.split(command))
    logging.debug('read current responses file: %s', responses_file)
    with responses_file.open('rb+') as responses_fh:
        if responses == responses_fh.read_bytes():
            logging.debug('No update required')
            return False
        responses_fh.seek(0)
        logging.debug('Updating response file: %s', responses_file)
        responses_fh.write_bytes(responses)
    return True


def main():
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    config = ConfigParser()
    config.read(args.config)
    if args.signer not in config.sections():
        logging.error('%s is not a configured signer', args.signer)
        return 1
    try:
        dbconfig = config[args.signer]['dbconfig']
    except KeyError:
        logging.error('%s unable to find dbconfig', args.signer)
        return 1
    try:
        ocsprefresh(dbconfig, args.responder_cert, args.responder_key, args.ca_file)
    except CalledProcessError as error:
        logging.error('ocsprefresh failed: %s', error)
        return 1
    try:
        if ocspdump(dbconfig, args.responses_file):
            check_call(shlex.split(f"/usr/bin/systemctl restart {args.restart_service}"))
    except CalledProcessError as error:
        logging.error('ocspdump failed: %s', error)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
