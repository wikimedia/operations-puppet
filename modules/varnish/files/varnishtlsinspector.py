#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  Varnishtlsinspector
  ~~~~~~~~~~~~~~~~~~~
  Varnishtlsinspector is responsible for gathering request information
  for requests using specific TLS ciphersuites. Currently the ones
  using RSA as the key exchange algorithm.

  Copyright 2018 Valentin Gutierrez <vgutierrez@wikimedia.org>
  Copyright 2016-2018 Emanuele Rocca <ema@wikimedia.org>
  Copyright 2017-2018 Gilles Dubuc <gilles@wikimedia.org>

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


class VarnishTLSInpector(object):
    description = 'Varnish TLS ciphersuites logstash logger'

    def __init__(self, argument_list):
        """Parse CLI arguments.

        argument_list is a list such as ['--foo', 'FOO', '--bar', 'BAR']"""
        ap = argparse.ArgumentParser(
            description=self.description,
            epilog='If no logstash server is specified, '
                   'prints log entries to stdout instead.')

        ap.add_argument('--logstash-server', help='logstash server',
                        type=parse_logstash_server_string, default=None)

        ap.add_argument('--transaction-timeout', help='varnish transaction timeout',
                        type=int, default=600)

        ap.add_argument('--varnishd-instance-name', help='varnishd instance name',
                        default=None)

        ap.add_argument('--varnishlog-path', help='varnishlog full path',
                        default='/usr/bin/varnishlog')

        self.args = ap.parse_args(argument_list)

        self.query = [
            'ReqMethod ne PURGE',
            'ReqHeader:X-Forwarded-Proto eq https',
            'ReqHeader:X-CP-Key-Exchange eq RSA',
        ]

        self.cmd = [
            self.args.varnishlog_path,
            '-g', 'raw',
            # Query for HTTPS requests using RSA key exchange
            '-q', ' and '.join(self.query),
            # Set maximum Varnish transaction duration to track
            '-T', '%d' % self.args.transaction_timeout,
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
                message_type='logback',
                tags=['varnishtlsinspector']
            )
        else:
            handler = logging.StreamHandler(sys.stdout)

        handler.setLevel(logging.DEBUG)

        self.logger = logging.getLogger('varnishtlsinspector')
        self.logger.setLevel(logging.DEBUG)
        self.logger.addHandler(handler)

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
            if 'request-User-Agent' in self.tx and 'log-CP-Full-Cipher' in self.tx:
                self.logger.info(self.tx['log-CP-Full-Cipher'] + self.tx['request-User-Agent'],
                                 extra=self.tx)
            self.tx = {}
        elif tag == 'ReqHeader':
            splitagain = value.split(None, 1)
            header_name = splitagain[0][:-1]

            if header_name == 'User-Agent':
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

            if header_name == 'X-Client-IP':
                if len(splitagain) == 2:
                    header_value = splitagain[1]
                else:
                    # Similarly to ReqHeader above, RespHeader can also occasionaly
                    # have no associated value.
                    header_value = ''

                self.tx['response-' + header_name] = header_value
        elif tag == 'VCL_Log':
            splitagain = value.split(None, 1)
            log_name = splitagain[0][:-1]

            if log_name in ['CP-TLS-Version', 'CP-Key-Exchange',
                            'CP-Auth', 'CP-Cipher', 'CP-Full-Cipher']:
                if len(splitagain) == 2:
                    log_value = splitagain[1]
                else:
                    log_value = ''

                self.tx['log-' + log_name] = log_value

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
    VarnishTLSInpector(sys.argv[1:]).main()
