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
"""

__author__ = 'Andrew Otto <otto@wikimedia.org>'

import argparse
import datetime
from diamond.collector import Collector
from multiprocessing import Manager, Process
import os
import subprocess
import sys
import time
import unittest

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
    'invalid': 0,
}
# Include valid http_methods in default_counts.
for m in valid_http_methods:
    default_counts['method.' + m] = 0

def count_requests(request_tuples, shared_dict):
    """
    Iterates over request_tuples which should be of the form
    [(http_method, http_status), ...] and increments counts
    in shared_dict. http_method and http_status must validate
    in order to be counted properly, otherwise the request
    will be counted as invalid.
    """

    for (http_method, http_status) in request_tuples:
        # If request was invalid, then increment
        # invalid request count metric.
        if not (
            is_valid_http_method(http_method) and
            is_valid_http_status(http_status)
        ):
            shared_dict['invalid'] += 1
            continue

        # Increment total request seen.
        shared_dict['total'] += 1

        # Increment http_status_class metric.
        shared_dict['status.' + http_status[0] + 'xx'] += 1

        # Increment http_status metric.
        http_status_key = 'status.' + http_status
        shared_dict[http_status_key] = (
            shared_dict.setdefault(http_status_key, 0) + 1
        )

        # Increment ok/error status metric.
        if http_status[0] in '123':
            shared_dict['status.ok'] += 1
        elif http_status[0] in '45':
            shared_dict['status.error'] += 1

        # Increment http_method metric.
        shared_dict['method.' + http_method.lower()] += 1


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


def varnishncsa_request_tuples(
    varnishname=None,
    varnishncsa='/usr/bin/varnishncsa'
):
    """
    Returns an iterator of (http_method, http_status) tuples
    obtained by running varnishncsa in a subprocess and
    wrapping that process' stdout in a tuple generator.
    """

    # Run varnishncsa only showing HTTP method
    # and HTTP status for each request
    command = [varnishncsa, '-F', '%m %s']
    if varnishname:
        command += ['-n', varnishname]

    subproc = subprocess.Popen(command, stdout=subprocess.PIPE)

    for line in subproc.stdout:
        try:
            yield tuple(line.rstrip().split(' ', 1))
        except ValueError:
            pass


def get_shared_dict():
    """
    Returns a Manager DictProxy pre-populated with
    request stats that we always want to report.
    """
    return Manager().dict(default_counts)


def init_counter_process(varnishname):
    """
    Returns a (Process, DictProxy) tuple.  The DictProxy wil
    be updated by Process once Process.start() is called.
    """

    shared_dict = get_shared_dict()
    counter_process = Process(
        target=count_requests,
        args=(varnishncsa_request_tuples(varnishname), shared_dict)
    )
    return (counter_process, shared_dict)


class VarnishstatsCollector(Collector):

    def __init__(self, *args, **kwargs):
        super(VarnishstatsCollector, self).__init__(*args, **kwargs)

        # Initialize self.counter_process and self.shared_dict.
        (self.counter_process, self.shared_dict) = init_counter_process(
            self.config['varnishname']
        )
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
        Publishes items collected in shared_dict.
        """
        for key in shared_dict.keys():
            self.publish(key, shared_dict[key])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('--varnishname', default=None)
    parser.add_argument('--interval', default=1, type=int)
    arguments = parser.parse_args()

    (counter_process, shared_dict) = init_counter_process(
        arguments.varnishname
    )
    counter_process.start()

    while True:
        time.sleep(arguments.interval)
        print_counts(shared_dict)


# ##### Tests ######
# To run:
#   python -m unittest varnishstats-diamond-collector
#
class TestVarnishstats(unittest.TestCase):
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

    def test_count_requests(self):
        t = [
            ('GET', '200'),
            ('POST', '200'),
            ('GET', '204'),
            ('GET', '304'),
            ('GET', '500'),
            ('nogood', '300'),
            ('GET', 'nogood'),
        ]

        d = get_shared_dict()
        count_requests(t, d)

        self.assertEqual(d['method.get'], 4)
        self.assertEqual(d['method.post'], 1)

        self.assertEqual(d['status.200'], 2)
        self.assertEqual(d['status.2xx'], 3)
        self.assertEqual(d['status.304'], 1)
        self.assertEqual(d['status.3xx'], 1)
        self.assertEqual(d['status.500'], 1)
        self.assertEqual(d['status.5xx'], 1)

        self.assertEqual(d['status.error'], 1)
        self.assertEqual(d['status.ok'], 4)

        self.assertEqual(d['total'], 5)
        self.assertEqual(d['invalid'], 2)
