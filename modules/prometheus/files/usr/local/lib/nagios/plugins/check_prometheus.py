#!/usr/bin/python3

# Author: Filippo Giunchedi <filippo@wikimedia.org>
# Copyright 2018 Wikimedia Foundation
# Copyright 2018 Filippo Giunchedi
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


import argparse
import math
import operator
import sys

import requests


EX_OK = 0
EX_WARNING = 1
EX_CRITICAL = 2
EX_UNKNOWN = 3

PREDICATE = {
    'le': operator.le,
    'ge': operator.ge,
    'gt': operator.gt,
    'lt': operator.lt,
    'eq': operator.eq,
}

PREDICATE_TO_STR = {
    operator.ge: '>=',
    operator.le: '<=',
    operator.lt: '<',
    operator.gt: '>',
    operator.eq: '==',
}


class PrometheusCheck(object):
    def __init__(self, url, timeout=5):
        self.url = url
        self.query_url = self.url + '/api/v1/query'
        self.timeout = timeout

    def _run_query(self, query):
        try:
            response = requests.get(self.query_url, params={'query': query}, timeout=self.timeout)
            return (EX_OK, response.json())
        except requests.exceptions.RequestException as e:
            return (EX_CRITICAL, '{} error while fetching: {}'.format(self.query_url, e))
        except requests.exceptions.Timeout as e:
            return (EX_CRITICAL, '{} timeout while fetching: {}'.format(self.query_url, e))
        except ValueError as e:
            return (EX_CRITICAL, '{} error while decoding json: {}'.format(self.query_url, e))

    def _check_vector(self, result, predicate, warning, critical, nan_ok=False):
        raise NotImplementedError()

    def _check_scalar(self, result, predicate, warning, critical, nan_ok=False):
        try:
            value = float(result[1])
        except ValueError as e:
            return EX_CRITICAL

        if math.isnan(value):
            if nan_ok:
                return (EX_OK, 'NaN')
            else:
                return (EX_UNKNOWN, 'NaN')

        if predicate(value, critical):
            text = '{} {} {}'.format(value, PREDICATE_TO_STR.get(predicate), critical)
            return (EX_CRITICAL, text)
        elif predicate(value, warning):
            text = '{} {} {}'.format(value, PREDICATE_TO_STR.get(predicate), warning)
            return (EX_WARNING, text)
        else:
            return (EX_OK, '')

    def check_query(self, query, warning, critical, predicate=operator.ge, nan_ok=False):
        status, result = self._run_query(query)
        if status != EX_OK:
            return status, result

        if result['status'] == 'error':
            error_type = result.get('errorType', 'n/a')
            error = result.get('error', 'n/a')
            return (EX_CRITICAL, '{}: {}'.format(error_type, error))

        metric_data = result['data']['result']
        if result['data']['resultType'] == 'vector':
            return self._check_vector(metric_data, predicate, warning, critical, nan_ok)
        else:
            return self._check_scalar(metric_data, predicate, warning, critical, nan_ok)


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--url', default='http://localhost:9090',
                        help='Prometheus server URL')
    parser.add_argument('--timeout', default=10, type=int, metavar='SECONDS',
                        help='Timeout for the request to complete')
    parser.add_argument('-c', '--critical', type=float, metavar='FLOAT',
                        help='Threshold for critical status')
    parser.add_argument('-w', '--warning', type=float, metavar='FLOAT',
                        help='Threshold for warning status')
    parser.add_argument('-m', '--method', metavar='METHOD',
                        choices=PREDICATE.keys(), default='ge',
                        help='Comparison method')
    parser.add_argument('--nan-ok', action='store_true', default=False,
                        help='NaN results are acceptable')
    parser.add_argument('query', nargs='*',
                        help='The query to run on Prometheus')
    options = parser.parse_args()
    if not (options.warning and options.critical):
        parser.error('warning and critical thresholds are required')

    check = PrometheusCheck(options.url, options.timeout)
    query = options.query[0]
    status, text = check.check_query(query, options.warning, options.critical,
                                     PREDICATE.get(options.method), options.nan_ok)

    if status == EX_OK:
        text = 'OK - {!r} within thresholds {}'.format(query, text)
    if status == EX_WARNING:
        text = 'WARNING - {!r}: {}'.format(query, text)
    if status == EX_CRITICAL:
        text = 'CRITICAL - {!r}: {}'.format(query, text)
    if status == EX_UNKNOWN:
        text = 'UNKNOWN - {!r}: {}'.format(query, text)

    print(text)
    return status


if __name__ == '__main__':
    sys.exit(main())
