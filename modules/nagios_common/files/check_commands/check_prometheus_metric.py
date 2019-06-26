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


"""Check a Prometheus query against the provided thresholds.

Float thresholds and checking vector results are supported, when vectors are returned by Prometheus
the key/value label pairs will be grouped by label key and the result printed as output of the
check.
"""

import argparse
import logging
import math
import operator
import os
import sys

import requests


EX_OK = 0
EX_WARNING = 1
EX_CRITICAL = 2
EX_UNKNOWN = 3

PREDICATE = {
    'eq': operator.eq,
    'ge': operator.ge,
    'gt': operator.gt,
    'le': operator.le,
    'lt': operator.lt,
}

# Using > and < won't work because they are stripped from output by default
# See also illegal_macro_output_chars setting
# https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/configmain.html
PREDICATE_TO_STR = {v: k for (k, v) in PREDICATE.items()}

log = logging.getLogger(__name__)


class PrometheusCheck(object):
    def __init__(self, url, timeout=5, retries=2):
        self.url = url
        self.query_url = self.url + '/api/v1/query'
        self.timeout = timeout
        self.session = requests.Session()
        self.session.mount(url, requests.adapters.HTTPAdapter(max_retries=retries))
        self.session.headers['User-agent'] = 'wmf-icinga/{} (root@wikimedia.org)'.format(
            os.path.basename(__file__))

    def _run_query(self, query):
        try:
            log.debug('Running %r on %r', query, self.query_url)
            response = self.session.get(self.query_url, params={'query': query},
                                        timeout=self.timeout)
            return (EX_OK, response.json())
        except requests.exceptions.Timeout as error:
            return (EX_UNKNOWN, '{} timeout while fetching: {}'.format(self.query_url, error))
        except requests.exceptions.RequestException as error:
            return (EX_UNKNOWN, '{} error while fetching: {}'.format(self.query_url, error))
        except ValueError as error:
            return (EX_UNKNOWN, '{} error while decoding json: {}'.format(self.query_url, error))

    @staticmethod
    def _group_all_labels(metrics):
        """Group metrics by all of their key/value label pairs."""
        labels = {}

        for metric in metrics:
            for key, value in metric.items():
                labels.setdefault(key, []).append(value)

        out = []
        for key, values in labels.items():
            # Skip meta-label used for the metric name.
            if key == '__name__':
                continue
            unique_values = sorted(set(values))
            if len(unique_values) > 1:
                out.append('%s={%s}' % (key, ','.join(unique_values)))
            else:
                out.append('%s=%s' % (key, ','.join(unique_values)))
        return sorted(out)

    @staticmethod
    def _check_vector(result, predicate, warning, critical, nan_ok=False):
        """Check a vector value against the warning/critical thresholds.

           Return matching metrics grouped by their key/value labels.
        """
        critical_metrics = []
        warning_metrics = []

        log.debug('Checking vector data for %r', result)
        for metric in result:
            try:
                value = float(metric['value'][1])
            except ValueError:
                return (EX_UNKNOWN, 'Error converting {!r} to float'.format(value))

            if math.isnan(value) and not nan_ok:
                return (EX_UNKNOWN, 'NaN')

            if predicate(value, critical):
                critical_metrics.append(metric['metric'])
            elif predicate(value, warning):
                warning_metrics.append(metric['metric'])

        # TODO(filippo): the label grouping is dumb, a better way would be for the user to specify
        # what labels should be grouped together.
        if critical_metrics:
            return (EX_CRITICAL, ' '.join(PrometheusCheck._group_all_labels(critical_metrics)))
        if warning_metrics:
            return (EX_WARNING, ' '.join(PrometheusCheck._group_all_labels(warning_metrics)))
        if not warning_metrics and not critical_metrics:
            text = 'All metrics within thresholds.'
            return (EX_OK, text)
        return (EX_UNKNOWN, 'Unable to determine status from {!r}'.format(result))

    def _check_scalar(self, result, predicate, warning, critical, nan_ok=False):
        """Check a scalar value against the warning/critical thresholds."""

        log.debug('Checking scalar data for %r', result)
        try:
            value = float(result[1])
        except ValueError:
            return (EX_CRITICAL, 'Cannot convert {!r} to float'.format(result[1]))

        if math.isnan(value):
            if nan_ok:
                return (EX_OK, 'NaN')
            return (EX_UNKNOWN, 'NaN')

        predicate_str = PREDICATE_TO_STR.get(predicate)
        if predicate(value, critical):
            text = '{:.4g} {} {:.4g}'.format(value, predicate_str, critical)
            return (EX_CRITICAL, text)
        if predicate(value, warning):
            text = '{:.4g} {} {:.4g}'.format(value, predicate_str, warning)
            return (EX_WARNING, text)
        text = '(C){0:.4g} {1} (W){2:.4g} {1} {3:.4g}'.format(
            critical, predicate_str, warning, value)
        return (EX_OK, text)

    def check_query(self, query, warning, critical, predicate=operator.ge, nan_ok=False):
        """Run a query on Prometheus and check the result against warning and critical
           thresholds."""
        status, result = self._run_query(query)
        if status != EX_OK:
            return status, result

        if result['status'] == 'error':
            error_type = result.get('errorType', 'n/a')
            error = result.get('error', 'n/a')
            return (EX_CRITICAL, '{}: {}'.format(error_type, error))

        metric_data = result['data']['result']

        want_scalar = False
        # Prometheus result type is scalar, obviously perform scalar check.
        if result['data']['resultType'] == 'scalar':
            want_scalar = True

        # Result is a single-element vector and no metric labels.
        if len(metric_data) == 1 and metric_data[0]['metric'] == {}:
            # Force a scalar check since for all intended purposes the result is a scalar.
            want_scalar = True
            metric_data = metric_data[0]['value']

        if want_scalar:
            return self._check_scalar(metric_data, predicate, warning, critical, nan_ok)
        return self._check_vector(metric_data, predicate, warning, critical, nan_ok)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--url', default='http://localhost:9090',
                        help='Prometheus server URL')
    parser.add_argument('--timeout', default=10, type=int, metavar='SECONDS',
                        help='Timeout for the request to complete')
    parser.add_argument('-c', '--critical', type=float, metavar='FLOAT', required=True,
                        help='Threshold for critical status')
    parser.add_argument('-w', '--warning', type=float, metavar='FLOAT', required=True,
                        help='Threshold for warning status')
    parser.add_argument('-m', '--method', metavar='METHOD',
                        choices=PREDICATE.keys(), default='ge',
                        help='Comparison method')
    parser.add_argument('--nan-ok', action='store_true', default=False,
                        help='NaN results are acceptable')
    parser.add_argument('--debug', action='store_true', default=False,
                        help='Turn on debug')
    parser.add_argument('query', nargs='+',
                        help='The query to run on Prometheus')
    options = parser.parse_args()

    if not PREDICATE.get(options.method)(options.critical, options.warning):
        parser.error('Thresholds not consistent with method: {} {} {}'.format(
            options.critical, options.method, options.warning))

    log_level = logging.INFO
    if options.debug:
        log_level = logging.DEBUG
    logging.basicConfig(level=log_level)
    logging.getLogger('requests.packages.urllib3').setLevel(logging.WARNING)
    logging.getLogger('urllib3.connectionpool').setLevel(logging.WARNING)

    check = PrometheusCheck(options.url, options.timeout)
    status, text = check.check_query(options.query[0], options.warning, options.critical,
                                     PREDICATE.get(options.method), options.nan_ok)

    print(text)
    return status


if __name__ == '__main__':
    sys.exit(main())
