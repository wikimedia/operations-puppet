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
import json
import logging
import logstash
import os
import sys
import traceback
from urllib.parse import urlparse

from collections import OrderedDict
from datetime import date, datetime
from subprocess import PIPE, Popen


# https://github.com/urbaniak/cee-formatter/blob/master/cee_formatter.py
# "cee" was MITRE' standard for logging, we're using the "@cee:" token in logs
# to identify JSON-formatted logs via mmjsonparse rsyslog module.

class CEEFormatter(logging.Formatter):
    IGNORED_FIELDS = (
        'args',
        'asctime',
        'created',
        'exc_info',
        'levelno',
        'module',
        'msecs',
        'message',
        'msg',
        'name',
        'pathname',
        'process',
        'relativeCreated',
        'thread',
    )

    def __init__(self, *args, **kwargs):
        self.ignored_fields = kwargs.get('ignored_fields', self.IGNORED_FIELDS)

        super(CEEFormatter, self).__init__(*args, **kwargs)

    def jsonhandler(self, obj):
        if isinstance(obj, datetime) and self.datefmt:
            return obj.strftime(self.datefmt)
        elif isinstance(obj, date) or isinstance(obj, datetime):
            return obj.isoformat()
        try:
            return str(obj)
        except Exception:
            return '<object of type \'{}\' cannot be converted to str>'.format(
                type(obj).__name__
            )

    def format(self, log_record):
        record = OrderedDict()

        record['time'] = datetime.utcfromtimestamp(log_record.created)

        record['message'] = log_record.getMessage()
        record['pid'] = log_record.process
        record['tid'] = log_record.thread
        record['level'] = log_record.levelname
        record['logger'] = log_record.name

        if log_record.exc_info:
            record['exception'] = '\n'.join(
                traceback.format_exception(*log_record.exc_info)
            )

        for k in sorted(log_record.__dict__.keys()):
            if log_record.__dict__[k] is not None and k not in self.ignored_fields:
                record[k] = log_record.__dict__[k]

        if record['threadName'] == 'MainThread':
            del record['threadName']

        if record['processName'] == 'MainProcess':
            del record['processName']

        return '@cee: %s' % (
            json.dumps(record, default=self.jsonhandler)
        )


def parse_logstash_server_string(server_string):
    """Convert logstash server string into (hostname, port) tuple."""
    parsed = urlparse('//' + server_string)
    return parsed.hostname, parsed.port or 12202


class BaseVarnishLogConsumer(object):
    description = 'Generic varnishlog consumer, must be extended'

    # Request and response headers to be sent to logstash
    request_headers = (
        "accept",
        "accept-encoding",
        "accept-language",
        "cookie",
        "host",
        "x-cdis",
        "x-client-ip",
        "x-seven",
        "user-agent",
    )
    response_headers = (
        "age",
        "accept-ranges",
        "backend-timing",
        "cache-control",
        "connection",
        "content-encoding",
        "content-type",
        "date",
        "etag",
        "expires",
        "server",
        "transfer-encoding",
        "vary",
        "x-cache-int",
        "x-powered-by",
        "x-cdis",
    )

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
            handler.setFormatter(CEEFormatter())

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
        elif tag in ('ReqMethod', 'BereqMethod'):
            self.tx['http-method'] = value
        elif tag in ('ReqURL', 'BereqURL'):
            self.tx['http-url'] = value
        elif tag in ('ReqProtocol', 'BereqProtocol'):
            self.tx['http-protocol'] = value
        elif tag in ('RespStatus', 'BerespStatus'):
            self.tx['http-status'] = value
        elif tag == 'Timestamp':
            splitagain = value.split()
            ts_name = splitagain[0][:-1].lower()
            self.tx['time-' + ts_name] = float(splitagain[3])
        elif tag in ('ReqHeader', 'BereqHeader'):
            splitagain = value.split(None, 1)
            header_name = splitagain[0][:-1]

            if len(splitagain) == 2:
                header_value = splitagain[1]
            else:
                # ReqHeader can occasionaly have no associated value. Set value
                # to empty string if that is the case.
                header_value = ''

            if header_name.lower() in self.request_headers:
                self.tx['request-' + header_name] = header_value
        elif tag in ('RespHeader', 'BerespHeader'):
            splitagain = value.split(None, 1)
            header_name = splitagain[0][:-1]

            if len(splitagain) == 2:
                header_value = splitagain[1]
            else:
                # Similarly to ReqHeader above, RespHeader can also occasionaly
                # have no associated value.
                header_value = ''

            if header_name.lower() in self.response_headers:
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
