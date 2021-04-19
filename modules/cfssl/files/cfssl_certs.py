#!/usr/bin/env python3
"""Script used to insert manually generated scripts into the database and also
via nrpe to check certificate expiry
"""
import json
import logging
import re

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

import pymysql

from cryptography import x509
from cryptography.hazmat.backends import default_backend


def get_args():
    """Parse arguments

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(
        description=__doc__, formatter_class=ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('-v', '--verbose', action='count')
    parser.add_argument(
        '-c', '--dbconfig', default='/etc/cfssl/db.conf.json', type=Path
    )

    sub = parser.add_subparsers(dest='command')
    insert_parser = sub.add_parser(
        'insert', help='insert a certificate to the database'
    )
    insert_parser.add_argument(
        'certificate', type=Path, help='the path to the certificate to insert'
    )

    check_parser = sub.add_parser(
        'check', help='Check the database for expiring certificates'
    )
    check_parser.add_argument(
        '-w', '--warning', default=28, type=int, help='warning value in days'
    )
    check_parser.add_argument(
        '-c', '--critical', default=14, type=int, help='critical value in days'
    )
    check_parser.add_argument('-l', '--long_output', action='store_true')
    check_parser.add_argument('ca_label')
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
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


def insert_certificate(db_conn, certificate):
    """Insert a certificate into the database

    Parameters:
        db_conn (`pymysql.connections.Connection`): A pymysql connection
        certifcate (str): a x509 ASCII pem blob
    """
    sql = (
        'INSERT INTO certificates '
        '(`serial_number`, `authority_key_identifier`, `ca_label`, `status`, `expiry`, `pem`) '
        'VALUES (%s, %s, %s, %s, %s, %s)'
    )
    cert = x509.load_pem_x509_certificate(certificate, default_backend())
    akid = cert.extensions.get_extension_for_oid(
        x509.oid.ExtensionOID.AUTHORITY_KEY_IDENTIFIER
    )
    issuer_cn = cert.issuer.get_attributes_for_oid(x509.NameOID.COMMON_NAME)[0]

    values = (
        cert.serial_number,
        akid.value.key_identifier,
        re.sub(r'\W', '_', issuer_cn.value),
        'good',
        cert.not_valid_after,
        certificate,
    )

    logging.debug('insert: %s', ', '.join(map(str, values)))
    with db_conn.cursor() as cursor:
        cursor.execute(sql, values)
    db_conn.commit()


def get_certificates_expire_state(db_conn, warning, critical, ca_label):
    """check the certificate database for expiring certificates

    Parameters
        db_conn (`pymysql.connections.Connection`): A pymysql connection
        warning (int): certificate should be considered warning if it expires in `warning` days
        critical (int): certificate should be considered critical if it expires in `critical` days

    Returns:
        dict: a dict representing certificates in a critical or warning state
    """
    results = {'warning': [], 'critical': [], 'expired': []}
    now = datetime.now()
    warning_date = now + timedelta(days=warning)
    critical_date = now + timedelta(days=critical)
    sql = 'SELECT pem, expiry FROM `certificates` WHERE `ca_label` = %s'
    logging.debug('Fetching certs')
    certs = defaultdict(dict)
    epoch = datetime.fromtimestamp(0)
    with db_conn.cursor() as cursor:
        cursor.execute(sql, ca_label)
        for cert in cursor.fetchall():
            logging.debug(cert)
            pem = x509.load_pem_x509_certificate(cert['pem'], default_backend())
            # CFSSL dosn;t clean up old certs so we need to make sure to check
            # the most recent cert
            if certs.get(pem.subject, {}).get('expiry', epoch) > cert['expiry']:
                continue
            certs[pem.subject]['expiry'] = cert['expiry']
            certs[pem.subject]['pem'] = pem
    for cert in certs.values():
        if cert['expiry'] < now:
            results['expired'].append(cert['pem'])
        elif cert['expiry'] < critical_date:
            results['critical'].append(cert['pem'])
        elif cert['expiry'] < warning_date:
            results['warning'].append(cert['pem'])
        else:
            logging.debug('%s: OK', cert['pem'].subject.rfc4514_string())
    return results


def icinga_report(certs_state, warning_days, critical_days, long_message=True):
    """print a report for icinga and return with the correct icinga exit code

    Once this function has been called you should avoid sending any additional data to stdout

    Arguments:
        certs_state (dict): a dictionary representing the warning and critical states of certs
        warning_date (int): The number of days valid days before a cert enters warning
        critical_date (int): The number of days valid days before a cert enters critical
        long_message (true): indicate if we should also output the icinga long message'

    Returns:
        int: Representing the icinga exit code
    """
    state = 'OK'
    return_code = 0
    summary_msg = []
    if certs_state['warning']:
        state = 'WARNING'
        return_code = 1
        summary_msg.append(
            '{} certs expiry in {} days'.format(
                len(certs_state['warning']), warning_days
            )
        )
    if certs_state['critical']:
        state = 'CRITICAL'
        return_code = 2
        summary_msg.append(
            '{} certs expiry in {} days'.format(
                len(certs_state['critical']), critical_days
            )
        )
    if not summary_msg:
        summary_msg = ['No certificates due to expire']

    print(f"{state} - {', '.join(summary_msg)}")
    if long_message:
        for certs in certs_state.values():
            for cert in certs:
                print(
                    f'\t{cert.subject.rfc4514_string()}: '
                    f"expires {cert.not_valid_after} , issuer {cert.issuer.rfc4514_string()}"
                )
    return return_code


def main():
    """main entry point

    Returns:
        int: an int representing the exit code
    """
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    config = json.loads(args.dbconfig.read_bytes())
    config['cursorclass'] = pymysql.cursors.DictCursor
    db_conn = pymysql.connect(**config)
    try:
        if args.command == 'insert':
            try:
                insert_certificate(db_conn, args.certificate.read_bytes())
            except x509.ExtensionNotFound:
                logging.error('%s: unable to get AKID not inserting', args.certificate)
                return 1
            except pymysql.err.IntegrityError:
                logging.error('%s: Already in database', args.certificate)
                return 1
        elif args.command == 'check':
            certs_state = get_certificates_expire_state(
                db_conn, args.warning, args.critical, args.ca_label
            )
            return icinga_report(
                certs_state, args.warning, args.critical, args.long_output
            )
    except pymysql.Error as error:
        logging.error('issue with SQL query: %s', error)
        if args.command == 'check':
            print('UNKNOWN: issue with SQL query ({})'.format(error))
            return 3
        return 1
    finally:
        db_conn.close()
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
