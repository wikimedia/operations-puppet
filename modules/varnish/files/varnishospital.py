#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  Varnishospital
  ~~~~~~~~~~~~~~
  Varnishospital is responsible for gathering origin servers transitions
  to/from sick/healthy state and sending the information to logstash.

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


class VarnishHospital(object):
    description = 'Varnish backend health logstash logger'

    def __init__(self, argument_list):
        """Parse CLI arguments.

        argument_list is a list such as ['--foo', 'FOO', '--bar', 'BAR']"""
        ap = argparse.ArgumentParser(
            description=self.description,
            epilog='If no logstash server is specified, '
                   'prints log entries to stdout instead.')

        ap.add_argument('--logstash-server', help='logstash server',
                        type=parse_logstash_server_string, default=None)

        ap.add_argument('--varnishd-instance-name', help='varnishd instance name',
                        default=None)

        ap.add_argument('--varnishlog-path', help='varnishlog full path',
                        default='/usr/bin/varnishlog')

        self.args = ap.parse_args(argument_list)

        self.cmd = [
            self.args.varnishlog_path,
            '-g', 'raw',
            # Query for "Back healthy" and "Went sick" events
            '-q', 'Backend_health ~ "Back healthy|Went sick"',
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
                tags=['varnishospital']
            )
        else:
            handler = logging.StreamHandler(sys.stdout)

        handler.setLevel(logging.DEBUG)

        self.logger = logging.getLogger('varnishospital')
        self.logger.setLevel(logging.DEBUG)
        self.logger.addHandler(handler)

    def handle_line(self, line):
        """
        Backend_health - Backend health check
              The result of a backend health probe.

              The format is:

                 %s %s %s %u %u %u %f %f %s
                 |  |  |  |  |  |  |  |  |
                 |  |  |  |  |  |  |  |  +- Probe HTTP response
                 |  |  |  |  |  |  |  +---- Average response time
                 |  |  |  |  |  |  +------- Response time
                 |  |  |  |  |  +---------- Probe window size
                 |  |  |  |  +------------- Probe threshold level
                 |  |  |  +---------------- Number of good probes in window
                 |  |  +------------------- Probe window bits
                 |  +---------------------- Status message
                 +------------------------- Backend name

        0 Backend_health - vcl-588a49bd-7406-45ad-ae6e-a9fc9fbcc496.be_cp1008_wikimedia_org \
                Went sick ------- 2 3 5 0.000000 0.000435
        0 Backend_health - vcl-588a49bd-7406-45ad-ae6e-a9fc9fbcc496.be_cp1008_wikimedia_org \
                Back healthy 4--X-RH 3 3 5 0.000460 0.000494 HTTP/1.1 200 OK
        """
        splitline = line.split(None)

        log = {
            'origin_server': splitline[3],
            'transition': "{} {}".format(splitline[4], splitline[5]),
            'window_bits': splitline[6],
            'good_probes': int(splitline[7]),
            'probe_threshold': int(splitline[8]),
            'probe_window_size': int(splitline[9]),
            'response_time': float(splitline[10]),
            'avg_response_time': float(splitline[11]),
            'http_response': " ".join(splitline[12:]),
        }

        self.logger.info("{} {}".format(log['origin_server'], log['transition']), extra=log)

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
    VarnishHospital(sys.argv[1:]).main()
