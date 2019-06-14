#!/usr/bin/python3

"""Elasticsearch number of masters eligible check.

Simple script to alert when the number of masters eligible is below a set threshold.

Example:
    $ python3 check_elasticsearch_masters_eligible.py
    $ python3 check_elasticsearch_masters_eligible.py --warning 3 --critical 2

"""

import argparse
import sys

import requests


EX_OK = 0
EX_WARNING = 1
EX_CRITICAL = 2
EX_UNKNOWN = 3


def get_nodes_role(base_url, timeout):
    url = "{base_url}/_cat/nodes?format=json&h=node.role".format(base_url=base_url)
    resp = requests.get(url, timeout=timeout)
    return resp.json()


def count_eligible_masters(nodes_role):
    return len(list(filter(lambda node: node['node.role'].startswith('m'), nodes_role)))


def alert(actual, warning, critical):
    if actual <= critical:
        log_output('CRITICAL', "Found {actual} eligible masters.".format(actual=actual))
        return EX_CRITICAL
    elif actual <= warning:
        log_output('WARNING', "Found {actual} eligible masters.".format(actual=actual))
        return EX_WARNING
    log_output('OK', 'All good')
    return EX_OK


def log_output(status, msg):
    print("{status} - {msg}".format(status=status, msg=msg))


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--url', default='http://localhost:9200',
                        help='Elasticsearch endpoint')
    parser.add_argument('--timeout', default=4, type=int, metavar='SECONDS',
                        help='Timeout for the request to complete'),
    parser.add_argument('--warning', type=int, default=2, metavar='WARNING',
                        help='Warning threshold for number of expected eligible masters')
    parser.add_argument('--critical', type=int, default=2, metavar='CRITICAL',
                        help='Critical threshold for number of expected eligible masters ')
    opt = parser.parse_args()

    try:
        nodes_role = get_nodes_role(opt.url, opt.timeout)
        actual_count = count_eligible_masters(nodes_role)
        return alert(actual_count, opt.warning, opt.critical)
    except Exception as e:
        log_output('UNKNOWN', e)
        return EX_UNKNOWN


if __name__ == '__main__':
    sys.exit(main())
