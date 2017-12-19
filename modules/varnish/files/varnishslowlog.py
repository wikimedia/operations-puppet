#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  VarnishSlowLog
  ~~~~~~~~~~~~~~
  VarnishSlowLog is responsible for gathering slow requests from varnishlog
  and sending them to logstash.

  Copyright 2016-2017 Emanuele Rocca <ema@wikimedia.org>
  Copyright 2017 Gilles Dubuc <gilles@wikimedia.org>

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
import urlparse

from subprocess import PIPE, Popen


def parse_logstash_server_string(server_string):
    """Convert logstash server string into (hostname, port) tuple."""
    parsed = urlparse.urlparse('//' + server_string)
    return parsed.hostname, parsed.port or 12202


class VarnishSlowLog(object):
    description = 'Varnish slow log logstash logger'

    def __init__(self, argument_list):
        """Parse CLI arguments.

        argument_list is a list such as ['--foo', 'FOO', '--bar', 'BAR']"""
        ap = argparse.ArgumentParser(
            description=self.description,
            epilog='If no logstash server is specified, '
                   'prints log entries to stdout instead.')

        ap.add_argument('--logstash-server', help='logstash server',
                        type=parse_logstash_server_string, default=None)

        ap.add_argument('--slow-threshold', help='varnish fetch duration threshold',
                        type=float, default=10.0)

        ap.add_argument('--transaction-timeout', help='varnish transaction timeout',
                        type=int, default=600)

        ap.add_argument('--varnishd-instance-name', help='varnishd instance name',
                        default=None)

        ap.add_argument('--varnishlog-path', help='varnishlog full path',
                        default='/usr/bin/varnishlog')

        self.args = ap.parse_args(argument_list)

        self.cmd = [
            self.args.varnishlog_path,
            # VSL query matching anything but purges
            '-q', 'ReqMethod ne "PURGE" and Timestamp:Fetch[3] > %f' % self.args.slow_threshold,
            # Set maximum Varnish transaction duration to track
            '-T', '%d' % self.args.transaction_timeout
        ]

        self.layer = 'backend'

        if self.args.varnishd_instance_name:
            self.cmd.extend(['-n', self.args.varnishd_instance_name])
            self.layer = self.args.varnishd_instance_name

        if self.args.logstash_server:
            handler = logstash.LogstashHandler(
                self.args.logstash_server[0],
                port=self.args.logstash_server[1],
                version=1,
                message_type='varnishslowlog'
            )
        else:
            handler = logging.StreamHandler(sys.stdout)

        handler.setLevel(logging.DEBUG)

        self.logger = logging.getLogger('varnishslowlog')
        self.logger.setLevel(logging.DEBUG)
        self.logger.addHandler(handler)

        self.tx = {}

    def handle_line(self, line):
        splitline = line.split(None, 2)

        # Ignore any line that doesn't have at least the 2 parts expected
        # for a transacation data field
        if len(splitline) < 2:
            return

        # Ignore any line that doesn't contain transaction data
        if splitline[0] != '-':
            return

        tag = splitline[1]

        if len(splitline) > 2:  # The End tag has no 3rd part
            value = splitline[2]

        if tag == 'Begin':
            splitagain = value.split()
            self.tx = {'id': splitagain[1], 'layer': self.layer}
        elif tag == 'End':
            if 'request-Host' in self.tx and 'http-url' in self.tx:
                self.logger.info(self.tx['request-Host'] + self.tx['http-url'], extra=self.tx)
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
            header_value = splitagain[1]
            self.tx['request-' + header_name] = header_value
        elif tag == 'RespHeader':
            splitagain = value.split(None, 1)
            header_name = splitagain[0][:-1]
            header_value = splitagain[1]
            self.tx['response-' + header_name] = header_value

    def main(self):
        """Execute the command specified in self.cmd and call handle_record for
        each output line produced by the command"""
        p = Popen(self.cmd, stdout=PIPE, bufsize=-1)

        try:
            while True:
                line = p.stdout.readline().rstrip('\n')
                self.handle_line(line)
        except KeyboardInterrupt:
            os.waitpid(p.pid, 0)


if __name__ == "__main__":
    VarnishSlowLog(sys.argv[1:]).main()
