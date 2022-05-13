#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Script used to insert manually generated scripts into the database and also
via nrpe to check certificate expiry
"""
import json
import logging
import re
import shlex

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path
from subprocess import check_output, CalledProcessError

import pymysql

from cryptography import x509
from cryptography.hazmat.backends import default_backend


def get_args():
    """Parse arguments

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """

    revoke_reasons = [
        'unspecified',
        'keyCompromise',
        'cACompromise',
        'affiliationChanged',
        'superseded',
        'cessationOfOperation',
        'certificateHold',
        'removeFromCRL',
        'privilegeWithdrawn',
        'aACompromise',
    ]

    parser = ArgumentParser(
        description=__doc__, formatter_class=ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('-v', '--verbose', action='count')
    parser.add_argument(
        '--dbconfig',
        default='/etc/cfssl/db.conf.json',
        type=Path,
        help='The cfssl json config file',
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

    list_parser = sub.add_parser('list', help='list details about certificates')
    list_parser.add_argument('-R', '--only-recent', action='store_true')
    list_parser.add_argument('ca_label', nargs='?')

    revoke_parser = sub.add_parser('revoke', help='list details about certificates')
    revoke_parser.add_argument(
        '-R',
        '--reason',
        choices=revoke_reasons,
        default='unspecified',
        help='The revocation reason',
    )
    revoke_parser.add_argument(
        '--dbconfig',
        default='/etc/cfssl/db.conf',
        type=Path,
        help='The cfssl db.conf file',
    )
    revoke_parser.add_argument(
        'certificate', type=Path, help='The path to the certificate to revoke'
    )

    sub.add_parser('clean', help='clean out expired certificates')
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


def filter_recent(certs):
    """Filter a n array of certs and return only
    the most recent for a CN/subject"""
    epoch = datetime.fromtimestamp(0)
    results = defaultdict(dict)

    for cert in certs:
        hash_key = (
            cert['x509'].subject.rfc4514_string() + cert['x509'].issuer.rfc4514_string()
        )
        if results[hash_key].get('expiry', epoch) > cert['expiry']:
            continue
        results[hash_key] = cert
    return results.values()


def get_certificates(db_conn, only_recent=True, ca_label=None):
    """Get a list of certificates"""
    sql = 'SELECT pem, expiry FROM `certificates`'
    certs = []
    logging.debug('Fetching certs')
    with db_conn.cursor() as cursor:
        if ca_label is None:
            cursor.execute(sql)
        else:
            sql = sql + '  WHERE `ca_label` = %s'
            cursor.execute(sql, ca_label)
        for cert in cursor.fetchall():
            parsed_x509 = x509.load_pem_x509_certificate(cert['pem'], default_backend())
            certs.append(
                {
                    'x509': parsed_x509,
                    'expiry': cert['expiry'],
                }
            )
    if only_recent:
        return filter_recent(certs)
    return certs


def list_certificates(db_conn, only_recent=False, ca_label=None):
    """print details about the current certs"""
    for cert in get_certificates(db_conn, only_recent, ca_label):
        print(
            f'{cert["x509"].subject.rfc4514_string()}: '
            f'expires {cert["x509"].not_valid_after} , '
            f'issuer {cert["x509"].issuer.rfc4514_string()}'
        )


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

    for cert in get_certificates(db_conn, True, ca_label):
        if cert['expiry'] < now:
            results['expired'].append(cert['x509'])
        elif cert['expiry'] < critical_date:
            results['critical'].append(cert['x509'])
        elif cert['expiry'] < warning_date:
            results['warning'].append(cert['x509'])
        else:
            logging.debug('%s: OK', cert['x509'].subject.rfc4514_string())
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


def revoke_certificate(certificate: Path, reason: str, dbconfig: Path) -> None:
    """Parse a x509 certificate file and return its serial as and akid

    Parameters:
        certificate (Path): Path to the x509 certificate
        reason (str): The revocation reason

    """
    parsed_x509 = x509.load_pem_x509_certificate(
        certificate.read_bytes(), default_backend()
    )
    akid = parsed_x509.extensions.get_extension_for_oid(
        x509.oid.ExtensionOID.AUTHORITY_KEY_IDENTIFIER
    ).value.key_identifier.hex()
    cmd = (
        f'/usr/bin/cfssl revoke -db-config {dbconfig} '
        f'-serial {parsed_x509.serial_number} -aki {akid} -reason {reason}'
    )

    logging.debug('running: %s', cmd)
    result = check_output(shlex.split(cmd))
    logging.debug(result)


def clean_expired_certs(db_conn):
    """Delete expired certificates

    Parameters
        db_conn (`pymysql.connections.Connection`): A pymysql connection
    """
    sql_certificates = 'DELETE FROM `certificates` WHERE `expiry` < NOW()'
    sql_ocsp_responses = 'DELETE FROM `ocsp_responses` WHERE `expiry` < NOW()'
    logging.debug('Deleting certs')
    with db_conn.cursor() as cursor:
        cursor.execute(sql_certificates)
        cursor.execute(sql_ocsp_responses)
    db_conn.commit()


def main():
    """main entry point

    Returns:
        int: an int representing the exit code
    """
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    error_code = 0
    if args.command == 'revoke':
        try:
            revoke_certificate(args.certificate, args.reason, args.dbconfig)
        except CalledProcessError as error:
            logging.error('Failed to revoke certificate: %s', error.output)
            error_code = error.returncode
        return error_code

    config = json.loads(args.dbconfig.read_bytes())
    config['cursorclass'] = pymysql.cursors.DictCursor
    db_conn = pymysql.connect(**config)
    try:
        if args.command == 'insert':
            try:
                insert_certificate(db_conn, args.certificate.read_bytes())
            except x509.ExtensionNotFound:
                logging.error('%s: unable to get AKID not inserting', args.certificate)
                error_code = 1
            except pymysql.err.IntegrityError:
                logging.error('%s: Already in database', args.certificate)
                error_code = 1
        elif args.command == 'check':
            certs_state = get_certificates_expire_state(
                db_conn, args.warning, args.critical, args.ca_label
            )
            return icinga_report(
                certs_state, args.warning, args.critical, args.long_output
            )
        elif args.command == 'list':
            list_certificates(db_conn, args.only_recent, args.ca_label)
        elif args.command == 'clean':
            clean_expired_certs(db_conn)

    except pymysql.Error as error:
        logging.error('issue with SQL query: %s', error)
        if args.command == 'check':
            print('UNKNOWN: issue with SQL query ({})'.format(error))
            error_code = 3
        error_code = 1
    finally:
        db_conn.close()
    return error_code


if __name__ == '__main__':
    raise SystemExit(main())
