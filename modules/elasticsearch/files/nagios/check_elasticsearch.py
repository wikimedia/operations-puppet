#!/usr/bin/python

# Author: Filippo Giunchedi <filippo@wikimedia.org>
# Copyright 2014 Wikimedia Foundation
# Copyright 2014 Filippo Giunchedi
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
import json
import operator
import re
import sys

import requests


EX_OK = 0
EX_WARNING = 1
EX_CRITICAL = 2
EX_UNKNOWN = 3


class Threshold(object):
    '''Implement a simple threshold parser/checker with common predicates and
    percentages.'''

    PREDICATES = {
        '<=': operator.le,
        '>=': operator.ge,
        '>': operator.gt,
        '<': operator.lt,
        '==': operator.eq,
    }

    def __init__(self, threshold):
        self.threshold_string = threshold
        self.predicate = None
        self.threshold = None
        self.percent = None
        self.FORMAT_RE = re.compile(
            r'^(%s)?\s*([\d.]+)\s*(%%)?' % '|'.join(self.PREDICATES))
        self._parse(threshold)

    def breach(self, value, total=None):
        if total is None and self.percent is not None:
            raise ValueError('threshold %r has percent but no total provided' %
                             self.threshold_string)
        if total not in [None, 0]:
            value = float(value) / total
        return self.predicate(value, self.threshold)

    def _parse(self, threshold):
        m = self.FORMAT_RE.match(threshold)
        if not m:
            raise ValueError('unable to parse threshold: %r' % threshold)
        predicate, value, percent = m.groups()
        try:
            value = float(value)
        except ValueError:
            raise ValueError('unable to parse as float: %r' % value)
        self.predicate = self.PREDICATES.get(predicate, operator.eq)
        self.threshold = value
        self.percent = percent


def _format_health(health):
    out = []
    for k, v in health.iteritems():
        health_item = '%s: %s' % (str(k).encode('utf8', 'ignore'),
                                  str(v).encode('utf8', 'ignore'))
        out.append(health_item)
    return ', '.join(out)


def check_status(health):
    if health['status'] != 'green':
        return EX_CRITICAL
    return EX_OK


def log_critical(log):
    print 'CRITICAL - elasticsearch %s' % log


def log_ok(log):
    print 'OK - elasticsearch %s' % log


def check_shards_inactive(health, threshold):
    total_shards = 0
    inactive_shards = 0
    for s in 'relocating', 'initializing', 'unassigned':
        inactive_shards += health['%s_shards' % s]
        total_shards += health['%s_shards' % s]
    total_shards += health['active_shards']
    t = Threshold(threshold)
    if not t.breach(inactive_shards, total_shards):
        return EX_OK

    log_critical('inactive shards %s threshold %s breach: %r' % (
                 inactive_shards, threshold, _format_health(health)))
    return EX_CRITICAL


def fetch_url(url, timeout, retries):
    exception = None

    for i in range(retries):
        try:
            response = requests.get(url, timeout=timeout)
            response.raise_for_status()
            return response
        except requests.exceptions.Timeout, e:
            exception = e
            continue
    raise exception


def check_elasticsearch(options):
    try:
        cluster_health_url = options.url + '/_cluster/health'
        response = fetch_url(cluster_health_url, options.timeout,
                             options.retries)
    except requests.exceptions.RequestException, e:
        log_critical('%s error while fetching: %s' % (cluster_health_url, e))
        return EX_CRITICAL

    try:
        cluster_health = json.loads(response.content)
    except ValueError, e:
        log_critical('%s error while decoding json: %s' % (
            cluster_health_url, e))
        return EX_CRITICAL

    r = check_shards_inactive(cluster_health, options.shards_inactive)
    if r != EX_OK:
        return r

    if not options.ignore_status:
        r = check_status(cluster_health)
        if r != EX_OK:
            return r

    log_ok('status %s: %s' % (cluster_health['cluster_name'],
                              _format_health(cluster_health)))
    return EX_OK


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--url', default='http://localhost:9200',
                        help='Elasticsearch endpoint')
    parser.add_argument('--timeout', default=4, type=int, metavar='SECONDS',
                        help='Timeout for the request to complete')
    parser.add_argument('--retries', default=2, type=int, metavar='INTEGER',
                        help='How many times to retry a request on timeout')
    parser.add_argument('--shards-inactive', default='>=0.1%',
                        dest='shards_inactive', metavar='THRESHOLD',
                        help='Threshold to check for inactive shards '
                             '(i.e. initializing/relocating/unassigned)')
    parser.add_argument('--ignore-status', default=False, action='store_true',
                        dest='ignore_status',
                        help='Do not check elasticsearch cluster status')
    options = parser.parse_args()

    return check_elasticsearch(options)


if __name__ == '__main__':
    sys.exit(main())
