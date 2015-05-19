#!/usr/bin/env python
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

import os
import sys
import time
import datetime
import subprocess

from multiprocessing import Manager, Process
from diamond.collector import Collector


def print_counts(counts):
    """
    Formats and orints out the contents of the counts dicts.
    """
    keys = counts.keys()
    keys.sort()
    print(
        datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S').center(31, '-')
    )
    for k in keys:
        print("{0} {1}".format(str(counts[k]).rjust(10), k))
    print('')


def count_requests(shared_dict, varnishname=None):
    """
    Runs varnishncsa in a subprocess and parses the input line by line.
    Counts are stored in the shared_dict.
    """

    # Run varnishncsa only showing HTTP method
    # and HTTP status for each request
    command = ['varnishncsa', '-F', '%m %s']
    if varnishname:
        command += ['-n', varnishname]

    subproc = subprocess.Popen(command, stdout=subprocess.PIPE)

    for line in subproc.stdout:
        if len(line.split()) == 2:
            (http_method, http_status) = line.strip().split()

            shared_dict['total'] += 1

            # Only update status counts if valid HTTP status
            if (http_status[0].isdigit() and
                int(http_status[0]) > 0 and
                int(http_status[0]) <= 5):

                http_status_key = 'status.' + http_status
                http_status_class_key = 'status.' + http_status[0] + 'xx'

                shared_dict[http_status_class_key] += 1
                shared_dict[http_status_key] = (
                    shared_dict.setdefault(http_status_key, 0) + 1
                )

                if int(http_status[0]) in [1, 2, 3]:
                    shared_dict['status.ok'] += 1
                elif int(http_status[0]) in [4, 5]:
                    shared_dict['status.error'] += 1

            # Only update method counts if valid HTTP method
            http_method_key = 'method.' + http_method.lower()
            if http_method_key in shared_dict.keys():
                shared_dict[http_method_key] = (
                    shared_dict.setdefault(http_method_key, 0) + 1
                )


def init_counter_process(varnishname):
    """
    Returns a (process, shared_dict) tuple.  shared_dict will be updated
    by process once process.start() is called.
    """
    manager = Manager()
    shared_dict = manager.dict()

    # Set some default counts we will always report.
    shared_dict.update({
        'status.1xx': 0,
        'status.2xx': 0,
        'status.3xx': 0,
        'status.4xx': 0,
        'status.5xx': 0,
        'status.ok': 0,
        'status.error': 0,

        'method.get': 0,
        'method.head': 0,
        'method.post': 0,
        'method.put': 0,
        'method.delete': 0,
        'method.trace': 0,
        'method.connect': 0,
        'method.options': 0,

        'total': 0,
    })

    counter_process = Process(
        target=count_requests,
        args=(shared_dict, varnishname)
    )
    return (counter_process, shared_dict)


class VarnishStatusCollector(Collector):

    def __init__(self, *args, **kwargs):
        super(VarnishStatusCollector, self).__init__(*args, **kwargs)
        (self.counter_process, self.shared_dict) = init_counter_process(
            self.config['varnishname']
        )
        self.counter_process.start()

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(VarnishStatusCollector, self).get_default_config()
        config.update({
            'site': None,
            'cachetype': None,
            'varnishname': None,
        })

        # Set metric name path prefix based on
        # several config parameters.

        path = 'varnish'
        if config['site']:
            path += '.' + config['site']
        if config['cachetype']:
            path += '.' + config['cachetype']
        if config['varnishname']:
            path += '.' + config['varnishname']
        path += '.request'

        config.update({
            'path': path
        })
        return config

    def collect(self):
        """
        Publishes stats to the configured path.
        e.g. /deployment-prep/hostname/availability/#
        with one # for each http status code
        """
        for k, v in self.shared_dict.iteritems():
            self.publish(k, v)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('--varnishname', default=None)
    parser.add_argument('--interval', default=1)
    arguments = parser.parse_args()

    (counter_process, shared_dict) = init_counter_process(
        arguments.varnishname
    )
    counter_process.start()

    while True:
        time.sleep(int(arguments.interval))
        print_counts(shared_dict)
