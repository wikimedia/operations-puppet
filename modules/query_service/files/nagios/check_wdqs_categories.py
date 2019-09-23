#!/usr/bin/python3

import argparse
import sys
from datetime import datetime, timedelta

import requests
from requests import HTTPError, ConnectionError

LAG_DESCRIPTION = 'wdqs categories lag'
PING_DESCRIPTION = 'wdqs categories ping'

EX_OK = 0
EX_WARNING = 1
EX_CRITICAL = 2
EX_UNKNOWN = 3

CATEGORIES_DATE_QUERY = 'SELECT (min(?date) as ?mindate) { ?wiki schema:dateModified ?date }'

HEADERS = {'User-Agent': 'wmf-icinga/check_wdqs_categories (root@wikimedia.org)'}


def check_categories_lag(base_url, timeout, warning_delay, critical_delay):
    try:
        json_response = execute_query(base_url, timeout, CATEGORIES_DATE_QUERY)
        lag = extract_lag(json_response)

        if lag < warning_delay:
            icinga_output('OK', LAG_DESCRIPTION, lag)
            return EX_OK
        elif lag < critical_delay:
            icinga_output('WARNING', LAG_DESCRIPTION, lag)
            return EX_WARNING
        else:
            icinga_output('CRITICAL', LAG_DESCRIPTION, lag)
            return EX_CRITICAL

    except ConnectionError:
        icinga_output('UNKNOWN', LAG_DESCRIPTION, 'Could not connect to WDQS')
    except (HTTPError, ValueError) as e:
        icinga_output('UNKNOWN', LAG_DESCRIPTION, e)
    return EX_UNKNOWN


def check_categories_ping(base_url, timeout):
    try:
        execute_query(base_url, timeout, CATEGORIES_DATE_QUERY)
        icinga_output('OK', PING_DESCRIPTION, 'successful')
    except Exception as e:
        icinga_output('CRITICAL', PING_DESCRIPTION, e)


def extract_lag(json_response):
    date_str = json_response['results']['bindings'][0]['mindate']['value']
    date = datetime.strptime(date_str, '%Y-%m-%dT%H:%M:%SZ')
    lag = datetime.utcnow() - date
    return lag


def execute_query(base_url, timeout, query):
    response = requests.get(
        base_url,
        timeout=timeout,
        params={
            'format': 'json',
            'query': query
        },
        headers=HEADERS)
    response.raise_for_status()
    return response.json()


def icinga_output(status, msg, details):
    print('{status} - {msg}: {details}'.format(status=status, msg=msg, details=details))


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--url', default='http://localhost:80/bigdata/namespace/categories/sparql',
                        help='WDQS Categories SPARQL endpoint')
    parser.add_argument('--timeout', default=2, type=int, metavar='SECONDS',
                        help='Timeout for the request to complete')
    parser.add_argument('--warning', default=3600*24*8, type=int, metavar='SECONDS',
                        help='Raise warning if lag exceeds this many seconds (default: 8 days)')
    parser.add_argument('--critical', default=3600*24*12, type=int, metavar='SECONDS',
                        help='Raise critical if lag exceeds this many seconds (default: 12 days)')

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--lag', action='store_true',
                       help='Checks the lag on categories update')
    group.add_argument('--ping', action='store_true',
                       help='Only checks that categories query works, ignore the timestamp')

    options = parser.parse_args()

    if options.lag:
        return check_categories_lag(
            options.url,
            options.timeout,
            timedelta(seconds=options.warning),
            timedelta(seconds=options.critical),
        )
    elif options.ping:
        return check_categories_ping(options.url, options.timeout)


if __name__ == '__main__':
    sys.exit(main())
