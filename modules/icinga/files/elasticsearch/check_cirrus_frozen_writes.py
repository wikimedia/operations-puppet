#!/usr/bin/python3

import argparse
import sys
from datetime import datetime, timedelta

import requests
from requests import HTTPError, ConnectionError

MSG_DESCRIPTION = 'elasticsearch / cirrus frozen writes'

EX_OK = 0
EX_WARNING = 1
EX_CRITICAL = 2
EX_UNKNOWN = 3

QUERY_PATH = '/mw_cirrus_metastore/mw_cirrus_metastore/freeze-everything'


def check_frozen_writes(base_url, timeout, warning_delay, critical_delay):
    try:
        response = requests.get(base_url + QUERY_PATH, timeout=timeout)

        if not is_frozen(response):
            icinga_output('OK', 'no freeze')
            return EX_OK

        response.raise_for_status()

        since = extract_since(response)

        if since < warning_delay:
            icinga_output('OK', since)
            return EX_OK
        elif since < critical_delay:
            icinga_output('WARNING', since)
            return EX_WARNING
        else:
            icinga_output('CRITICAL', since)
            return EX_CRITICAL

    except ConnectionError as e:
        log_unknown('Could not connect to Elasticsearch: ' + e.message)
    except HTTPError as e:
        log_unknown(e.message)
    except ValueError as ve:
        log_unknown(ve)
    return EX_UNKNOWN


def is_frozen(response):
    return response.status_code != 404 and response.json()['found']


def extract_since(response):
    json_response = response.json()
    date_str = json_response['_source']['timestamp']
    date = datetime.utcfromtimestamp(date_str, )
    lag = datetime.utcnow() - date
    return lag


def icinga_output(status, since):
    print('{status} - {msg}: {since}'.format(status=status, msg=MSG_DESCRIPTION, since=since))


def log_unknown(cause):
    print('UNKNOWN - {msg}: {cause}'.format(msg=MSG_DESCRIPTION, cause=cause))


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        '--url', default='http://localhost:9200',
        help='Elasticsearch endpoint')
    parser.add_argument(
        '--timeout', default=2, type=int, metavar='SECONDS',
        help='Timeout for the request to complete')
    parser.add_argument(
        '--warning', default=3600, type=int, metavar='SECONDS',
        help='Warning if writes have been frozen for more than this many seconds (default: 1h)')
    parser.add_argument(
        '--critical', default=3600*3, type=int, metavar='SECONDS',
        help='Critial if writes have been frozen for more than this many seconds (default: 3h)')
    options = parser.parse_args()

    return check_frozen_writes(
        options.url,
        options.timeout,
        timedelta(seconds=options.warning),
        timedelta(seconds=options.critical)
    )


if __name__ == '__main__':
    sys.exit(main())
