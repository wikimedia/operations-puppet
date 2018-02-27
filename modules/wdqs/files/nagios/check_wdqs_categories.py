#!/usr/bin/python3

import argparse
import json
import sys
from datetime import datetime, timedelta

import requests
from requests import HTTPError, ConnectionError

MSG_DESCRIPTION = 'wdqs categories lag'

EX_OK = 0
EX_WARNING = 1
EX_CRITICAL = 2
EX_UNKNOWN = 3

CATEGORIES_DATE_QUERY = 'SELECT (min(?date) as ?mindate) { ?wiki schema:dateModified ?date }'


def check_categories(base_url, timeout, warning_delay, critical_delay):
    try:
        json_response = execute_query(base_url, timeout, CATEGORIES_DATE_QUERY)
        lag = extract_lag(json_response)

        if lag < warning_delay:
            icinga_output('OK', lag)
            return EX_OK
        elif lag < critical_delay:
            icinga_output('WARNING', lag)
            return EX_WARNING
        else:
            icinga_output('CRITICAL', lag)
            return EX_CRITICAL

    except ConnectionError:
        log_unknown('Could not connect to WDQS')
    except (HTTPError, ValueError) as e:
        log_unknown(e.message)
    return EX_UNKNOWN


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
        })
    response.raise_for_status()
    return json.loads(response.content)


def icinga_output(status, lag):
    print('{status} - {msg}|{lag}'.format(status=status, msg=MSG_DESCRIPTION, lag=lag))


def log_unknown(cause):
    print('UNKNOWN - {msg}: {cause}'.format(msg=MSG_DESCRIPTION, cause=cause))


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
                        help='Raise warning if lag exceeds this many seconds (default: 12 days)')
    options = parser.parse_args()

    return check_categories(
        base_url=options.url,
        timeout=options.timeout,
        warning_delay=timedelta(seconds=options.warning),
        critical_delay=timedelta(seconds=options.critical)
    )


if __name__ == '__main__':
    sys.exit(main())
