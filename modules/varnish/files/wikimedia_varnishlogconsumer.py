# -*- coding: utf-8 -*-
"""
  VarnishLogConsumer
  ~~~~~~~~~~~~~~~~~~
  Base class for scripts consuming varnishlog data.

  Copyright 2016-2019 Emanuele Rocca <ema@wikimedia.org>
  Copyright 2017-2019 Gilles Dubuc <gilles@wikimedia.org>

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
import logging
import logstash
import os
import sys
from urllib.parse import urlparse

from subprocess import PIPE, Popen


def parse_logstash_server_string(server_string):
    """Convert logstash server string into (hostname, port) tuple."""
    parsed = urlparse('//' + server_string)
    return parsed.hostname, parsed.port or 12202


class BaseVarnishLogConsumer(object):
    description = 'Generic varnishlog consumer, must be extended'

    def __init__(self, argument_list):
        """Parse CLI arguments.

        argument_list is a list such as ['--foo', 'FOO', '--bar', 'BAR']"""
        ap = self.get_argument_parser()

        ap.add_argument('--logstash-server', help='logstash server',
                        type=parse_logstash_server_string, default=None)

        ap.add_argument('--transaction-timeout',
                        help='varnish transaction timeout',
                        type=int, default=600)

        ap.add_argument('--varnishd-instance-name',
                        help='varnishd instance name',
                        default=None)

        ap.add_argument('--varnishlog-path', help='varnishlog full path',
                        default='/usr/bin/varnishlog')

        self.args = ap.parse_args(argument_list)

        self.cmd = [self.args.varnishlog_path] + self.varnishlog_args()

        self.layer = 'backend'

        if self.args.varnishd_instance_name:
            self.cmd.extend(['-n', self.args.varnishd_instance_name])
            self.layer = self.args.varnishd_instance_name

        class_name = self.__class__.__name__.lower()

        if self.args.logstash_server:
            handler = logstash.LogstashHandler(
                self.args.logstash_server[0],
                port=self.args.logstash_server[1],
                version=1,
                message_type='logback',
                tags=[class_name]
            )
        else:
            handler = logging.StreamHandler(sys.stdout)

        handler.setLevel(logging.DEBUG)

        self.logger = logging.getLogger(class_name)
        self.logger.setLevel(logging.DEBUG)
        self.logger.addHandler(handler)

        self.tx = {}

    def get_argument_parser(self):
        return argparse.ArgumentParser(description=self.description)

    def varnishlog_args(self):
        return []

    def handle_end(self):
        pass

    def handle_tag(self, tag, value):
        pass

    def handle_line(self, line):
        splitline = line.split(None, 2)

        # Ignore any line that doesn't have at least the 2 parts expected
        # for a transacation data field
        if len(splitline) < 2:
            return

        # Ignore any line that doesn't contain transaction data. Interesting
        # lines have either - or -- in the first field depending on the chosen
        # grouping: single dash for vxid grouping, double when grouping by
        # request
        if splitline[0] not in ('-', '--'):
            return

        tag = splitline[1]

        if len(splitline) > 2:  # The End tag has no 3rd part
            value = splitline[2]

        if tag == 'Begin':
            splitagain = value.split()
            self.tx = {'id': splitagain[1], 'layer': self.layer}
        elif tag == 'End':
            self.handle_end()
            self.tx = {}
        elif tag == 'ReqMethod':
            self.tx['http-method'] = value
        elif tag == 'ReqURL':
            self.tx['http-url'] = value
        elif tag == 'ReqProtocol':
            self.tx['http-protocol'] = value
        elif tag == 'RespStatus':
            self.tx['http-status'] = value
        elif tag == 'Timestamp':
            splitagain = value.split()
            ts_name = splitagain[0][:-1].lower()
            self.tx['time-' + ts_name] = float(splitagain[3])
        elif tag == 'ReqHeader':
            splitagain = value.split(None, 1)
            header_name = splitagain[0][:-1]

            if len(splitagain) == 2:
                header_value = splitagain[1]
            else:
                # ReqHeader can occasionaly have no associated value. Set value
                # to empty string if that is the case.
                header_value = ''

            self.tx['request-' + header_name] = header_value
        elif tag == 'RespHeader':
            splitagain = value.split(None, 1)
            header_name = splitagain[0][:-1]

            if len(splitagain) == 2:
                header_value = splitagain[1]
            else:
                # Similarly to ReqHeader above, RespHeader can also occasionaly
                # have no associated value.
                header_value = ''

            self.tx['response-' + header_name] = header_value

            # Log Backend-Timing's D= value as floating seconds for easy
            # filtering and comparison.  This is set from WMF custom Apache
            # configurations, and technically only shows the delay from
            # request reception at Apache until response headers can be sent
            # by Apache.
            if header_name == 'Backend-Timing':
                try:
                    bt_us_str = header_value.split()[0].replace('D=', '')
                    bt_s = float(bt_us_str) / 1000000.0
                    self.tx['time-apache-delay'] = bt_s
                except ValueError:
                    pass
        else:
            self.handle_tag(tag, value)

    def main(self):
        """Execute the command specified in self.cmd and handle
        each line output by the command"""
        p = Popen(self.cmd, stdout=PIPE, bufsize=-1, universal_newlines=True)

        try:
            while True:
                line = p.stdout.readline().rstrip('\n')
                self.handle_line(line)
        except KeyboardInterrupt:
            os.waitpid(p.pid, 0)
