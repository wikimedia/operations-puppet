# -*- coding: utf-8 -*-
"""
  VarnishLogProcessor
  ~~~~~~~~~~~~~~~~~~~

  Processes Varnish log data and sends the output to statsd

  Copyright 2015 Ori Livneh <ori@wikimedia.org>
  Copyright 2015 Gilles Dubuc <gilles@wikimedia.org>

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
import socket
import urlparse


class VarnishLogProcessor:
    description = 'Varnish Log Processor'
    key_prefix = None
    statsd_server = None

    def __init__(self):
        ap = argparse.ArgumentParser(
            description=self.description,
            epilog='If no statsd server is specified, prints stats to stdout.'
        )

        print self.key_prefix

        ap.add_argument('--key-prefix', help='metric key prefix',
                        type=parse_prefix_string, default=self.key_prefix)
        ap.add_argument('--statsd-server', help='statsd server',
                        type=parse_statsd_server_string, default=None)
        args = ap.parse_args()

        if args.key_prefix is not None:
            self.key_prefix = args.key_prefix

        if args.statsd_server is not None:
            self.statsd_server = args.statsd_server

        if self.statsd_server:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

        self.stats = {}
        self.transactions = {}

        self.start()

    def handle_log_record(self, transaction_id, tag, record, remote_party):
        """VSL_handler_f callback function."""

        if tag == 'RxURL':
            # RxURL is the first tag we expect. If there are any existing
            # records for this transaction ID, we clear them away.
            self.transactions[transaction_id] = {tag: record}
        elif tag == 'ReqEnd':
            # ReqEnd is the last tag we expect. We pop the transaction's
            # records from the buffer and process it.
            transaction = self.transactions.pop(transaction_id, None)
            if transaction is not None:
                transaction[tag] = record
                self.process_transaction(transaction)
        else:
            # All other tags are buffered.
            transaction = self.transactions.get(transaction_id)
            if transaction is not None:
                transaction[tag] = record
        return 0

    def flush_stats(self):
        """Flush metrics to standard out or statsd server."""
        buf = io.BytesIO()
        while self.stats:
            key, value = self.stats.popitem()
            metric = '%s.%s:%s|c\n' % (self.key_prefix, key, value)
            buf.write(metric.encode('utf-8'))
        buf.seek(io.SEEK_SET)
        if self.statsd_server:
            self.sock.sendto(buf.read(), self.statsd_server)
        else:
            print(buf.read().decode('utf-8').rstrip())

    def process_transaction(self, transaction):
        pass

    def start():
        pass


def parse_statsd_server_string(server_string):
    parsed = urlparse.urlparse('//' + server_string)
    return parsed.hostname, parsed.port or 8125


def parse_prefix_string(prefix):
    print prefix

    prefix = prefix.strip('.')
    if not prefix:
        raise ValueError('Key prefix must not be empty')
    return prefix
