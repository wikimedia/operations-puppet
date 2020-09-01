#!/usr/bin/env python3
"""Script to dump OTRS aliases, alerting if the list is already a gsuite email"""

import logging
import smtplib

from argparse import ArgumentParser
from configparser import ConfigParser

import pymysql

LOG = logging.getLogger(__file__)


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-c', '--config', default='/etc/exim4/otrs.conf')
    parser.add_argument('-v', '--verbose', action='count')
    return parser.parse_args()


def get_log_level(args_level):
    """Configure logging"""
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG}.get(args_level, logging.DEBUG)


def verify_email(email, smtp_server):
    """Ensure email is a gsuite email address at smtp_server"""
    LOG.debug('Test: %s', email)
    smtp = smtplib.SMTP()
    smtp.connect(smtp_server)
    status, _ = smtp.helo()
    if status != 250:
        smtp.quit()
        raise ConnectionError('Failed helo status: {}'.format(status))
    smtp.mail('')
    status, _ = smtp.rcpt(email)
    smtp.quit()
    if status == 250:
        LOG.debug('Valid (%d): %s', status, email)
        return True
    LOG.debug('Invalid (%d): %s', status, email)
    return False


def main():
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    available, no_auth, gsuite = [], [], []
    valid_domains = []
    return_code = 0
    query = 'SELECT value0, create_time, change_time FROM system_address'

    config = ConfigParser()
    config.read(args.config)

    with open(config['DEFAULT']['valid_domains']) as config_fh:
        valid_domains = [line.strip() for line in config_fh.readlines()
                         if line.strip() and not line.startswith('#')]
    LOG.debug('valid domains: %s', ', '.join(valid_domains))

    try:
        conn = pymysql.connect(config['DB']['host'], config['DB']['user'],
                               config['DB']['pass'], config['DB']['name'])
        with conn.cursor() as cur:
            cur.execute(query)
            for row in cur.fetchall():
                if row[0].split('@')[1] not in valid_domains:
                    LOG.warning("we don't handle email for %s", row[0])
                    no_auth.append(row)
                    continue
                if verify_email(row[0], config['DEFAULT']['smtp_server']):
                    LOG.error("email is handled by gsuite: %s", row[0])
                    return_code = 1
                    gsuite.append(row)
                else:
                    available.append(row)
    except (pymysql.MySQLError, smtplib.SMTPServerDisconnected,
            smtplib.SMTPConnectError, ConnectionError) as error:
        LOG.error(error)
        return 1
    with open(config['DEFAULT']['aliases_file'], 'w') as aliases_fh:
        aliases_fh.writelines(['{}\n'.format(row[0]) for row in available])
    return return_code


if __name__ == '__main__':
    raise SystemExit(main())
