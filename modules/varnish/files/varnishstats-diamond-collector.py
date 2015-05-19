# -*- coding: utf-8 -*-
"""
Diamond collector for counting varnish HTTP requests
grouped by several dimensions, including:
  - Total requests
  - HTTP Status Code (200, 404, etc.)
  - HTTP Status Code Class (2xx, 3xx, etc.)
  - HTTP Status type (ok, error)
  - HTTP Method (GET, POST, etc.)

If run from the command line, these counts will be
printed to stdout.  Otherwise diamond will send them
off to statsd/graphite.

  Copyright 2015 Andrew Otto <otto@wikimedia.org>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  Author: Andrew Otto

"""
import argparse
import datetime
from diamond.collector import Collector
from multiprocessing import Manager, Process
import sys
import time
import unittest

from varnishlog import varnishlog

valid_http_methods = (
    'get',
    'head',
    'post',
    'put',
    'delete',
    'trace',
    'connect',
    'options',
    'purge',
)

# Initialize a dict of default counts
# we will always report.
default_counts = {
    'status.1xx': 0,
    'status.2xx': 0,
    'status.3xx': 0,
    'status.4xx': 0,
    'status.5xx': 0,
    'status.ok': 0,
    'status.error': 0,
    'total': 0,
}
# Include valid http_methods in default_counts.
for m in valid_http_methods:
    default_counts['method.' + m] = 0


def is_valid_http_method(m):
    """
    Returns True if m is in the list of valid_http_methods.
    """
    return m.lower() in valid_http_methods


def is_valid_http_status(s):
    """
    Returns True if s is in a valid HTTP status range.
    """
    try:
        return 100 <= int(s) < 600
    except ValueError:
        return False


def print_counts(counts):
    """
    Formats and prints out the contents of the counts dict.
    """
    keys = counts.keys()
    keys.sort()
    print(
        datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S').center(31, '-')
    )
    for k in keys:
        print("{0} {1}".format(str(counts[k]).rjust(10), k))
    print('')


def count_vsl_entries(vsl_args, counts=default_counts):
    """
    Starts varnishlog and stores counts for http status
    and http method in the counts dict.  If varnishlog
    finshes (because vsl_args has -k or -r), counts
    will be returned.  Otherwise, pass in a Manager DictProxy
    in as counts and access it in a different process.
    """

    def count_vsl_entry_callback(
        transaction_id,
        tag,
        value,
        remote_party
    ):
        # Count the http request method
        if tag == 'TxRequest' and is_valid_http_method(value):
            counts['method.' + value.lower()] += 1

        # Count the http response status
        elif tag == 'RxStatus' and is_valid_http_status(value):
            counts['status.' + value[0] + 'xx'] += 1
            http_status_key = 'status.' + value
            counts[http_status_key] = (
                counts.setdefault(http_status_key, 0) + 1
            )
            # Increment ok/error status metric.
            if value[0] in '123':
                counts['status.ok'] += 1
            elif value[0] in '45':
                counts['status.error'] += 1

        # ReqEnd indicates we completed a request, count it.
        # count it.
        elif tag == 'ReqEnd':
            counts['total'] += 1

    # Run varnishlog with the count_vsl_entry_callback
    # called for every VSL entry.
    varnishlog(vsl_args, count_vsl_entry_callback)
    return counts


def init_counter_process(extra_vsl_args=[]):
    """
    Returns a (Process, DictProxy) tuple.  The DictProxy wil
    be updated by Process once Process.start() is called.
    """

    shared_counts = Manager().dict(default_counts)

    vsl_args = [
        ('i', 'TxRequest'),
        ('i', 'RxStatus'),
        ('i', 'ReqEnd'),
    ]
    vsl_args += extra_vsl_args

    counter_process = Process(
        target=count_vsl_entries,
        args=(vsl_args, shared_counts)
    )
    return (counter_process, shared_counts)


class VarnishstatsCollector(Collector):

    def __init__(self, *args, **kwargs):
        super(VarnishstatsCollector, self).__init__(*args, **kwargs)

        # Initialize self.counter_process and self.counts.
        extra_vsl_args = []
        if self.config['varnishname']:
            extra_vsl_args.append(('n', self.config['varnishname']))

        self.counter_process, self.counts = init_counter_process(
            extra_vsl_args)
        # Start the counter_process.
        self.counter_process.start()

    def get_default_config(self):
        """
        Returns the default collector settings.
        """
        config = super(VarnishstatsCollector, self).get_default_config()
        config.update({
            'varnishname': None,
            'path': 'varnish.request'
        })

        return config

    def collect(self):
        """
        Publishes items collected in self.counts.
        """
        for key in self.counts.keys():
            self.publish(key, self.counts[key])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('--varnishname', default=None)
    parser.add_argument('--interval', default=1, type=int)
    arguments = parser.parse_args()

    extra_vsl_args = []
    if arguments.varnishname:
        extra_vsl_args.append(('n', arguments.varnishname))

    (counter_process, counts) = init_counter_process(
        extra_vsl_args
    )
    counter_process.start()

    while True:
        time.sleep(arguments.interval)
        print_counts(counts)


# ##### Tests ######
# To run:
#   python -m unittest varnishstats-diamond-collector
#
# This requires that varnishlog.test.data is present
# in the current directory.  It contains 100 entries
# spread across 6 transactions.  It was collected from
# a real text varnish server using the varnishlog utility.
#
class TestVarnishstats(unittest.TestCase):
    varnishlog_test_data_file = 'varnishlog.test.data'

    def test_is_valid_http_method(self):
        self.assertTrue(is_valid_http_method('GET'))
        self.assertTrue(is_valid_http_method('get'))
        self.assertTrue(is_valid_http_method('post'))
        self.assertFalse(is_valid_http_method('nogood'))

    def test_is_valid_http_status(self):
        self.assertTrue(is_valid_http_status('200'))
        self.assertTrue(is_valid_http_status('404'))
        self.assertTrue(is_valid_http_status(301))
        self.assertFalse(is_valid_http_status('nogood'))
        self.assertFalse(is_valid_http_status('1000'))

    def test_count_vsl_entries(self):
        # Test on 100 records from varnishlog.test.data file
        extra_vsl_args = [('r', self.varnishlog_test_data_file)]
        d = count_vsl_entries(extra_vsl_args)

        self.assertEqual(d['method.post'],  0)
        self.assertEqual(d['status.200'],   2)
        self.assertEqual(d['status.2xx'],   2)
        self.assertEqual(d['status.ok'],    2)
        self.assertEqual(d['status.error'], 0)
        self.assertEqual(d['total'],        2)
