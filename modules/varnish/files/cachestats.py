#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  cachestats
  ~~~~~~~~~~
  cachestats.CacheStatsSender is responsible for abstracting away any
  statsd-related operation, common to all our varnish python stats modules, as
  well as calling an external command (eg: varnishncsa) to read from VSM.
  Subclasses are responsible for dealing with the details of parsing the log
  entries and generating stats.

  Copyright 2016 Emanuele Rocca <ema@wikimedia.org>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

"""

import argparse
import io
import os
import socket
import time
import urlparse

from subprocess import PIPE, Popen


def parse_statsd_server_string(server_string):
    """Convert statsd server string into (hostname, port) tuple."""
    parsed = urlparse.urlparse('//' + server_string)
    return parsed.hostname, parsed.port or 8125


def parse_prefix_string(key_prefix):
    key_prefix = key_prefix.strip('.')
    if not key_prefix:
        raise ValueError('Key prefix must not be empty')
    return key_prefix


class CacheStatsSender(object):

    cmd = []
    description = ''

    def __init__(self, argument_list):
        """Parse CLI arguments, initialize self.stats and statsd socket.

        argument_list is a list such as ['--foo', 'FOO', '--bar', 'BAR']"""
        ap = argparse.ArgumentParser(
            description=self.description,
            epilog='If no statsd server is specified, '
                   'prints stats to stdout instead.')

        ap.add_argument('--statsd-server', help='statsd server',
                        type=parse_statsd_server_string, default=None)
        ap.add_argument('--key-prefix', help='metric key prefix',
                        type=parse_prefix_string, default='varnish.clients')
        ap.add_argument('--interval', help='send interval',
                        type=int, default=30)
        self.args = ap.parse_args(argument_list)

        self.next_pub = time.time() + self.args.interval

        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.stats = {}

    def gen_stats(self, record):
        """Update the self.stats dictionary. Implementation left to the
        subclasses"""
        raise NotImplementedError()

    def handle_record(self, record):
        """Update the self.stats dictionary by calling self.gen_stats. Send
        stats to statsd at regular intervals defined by self.args.interval"""
        self.gen_stats(record)

        now = time.time()
        if now >= self.next_pub:
            self.next_pub = now + self.args.interval
            buf = io.BytesIO()
            while self.stats:
                metric = '%s:%s|c\n' % self.stats.popitem()
                buf.write(metric.encode('utf-8'))
            buf.seek(io.SEEK_SET)
            if self.args.statsd_server:
                self.sock.sendto(buf.read(), self.args.statsd_server)
            else:
                print(buf.read().decode('utf-8', errors='replace').rstrip())

    def main(self):
        """Execute the command specified in self.cmd and call handle_record for
        each output line produced by the command"""
        p = Popen(self.cmd, stdout=PIPE, bufsize=-1)

        try:
            while True:
                line = p.stdout.readline()
                self.handle_record(line)
        except KeyboardInterrupt:
            os.waitpid(p.pid, 0)
