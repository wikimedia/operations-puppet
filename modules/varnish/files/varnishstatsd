#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  varnishstatsd
  ~~~~~~~~~~~~~
  Report backend response times and request counts aggregated by status.

  Usage: varnishstatsd [--statsd-server SERVER] [--key-prefix PREFIX]

    --statsd-server SERVER  statsd server
    --key-prefix PREFIX     metric key prefix

  If no statsd server is specified, prints stats to stdout instead.

  Copyright 2015-2016 Ori Livneh <ori@wikimedia.org>
            2016-2017 Emanuele Rocca <ema@wikimedia.org>

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
import io
import sys

from cachestats import CacheStatsSender

METRIC_FORMAT = (
    '%(key_prefix)s.%(backend)s.%(method)s:%(ttfb)d|ms\n'
    '%(key_prefix)s.%(backend)s.%(status)sxx:1|c\n'
)

UDP_MTU_BYTES = 1472


class StatsdStatsSender(CacheStatsSender):
    cmd = ['/usr/bin/varnishncsa', '-b',
           # Exclude client requests resulting in a pipe as they do not
           # generate a backend request. Varnish blindly passes on bytes in
           # both directions in that case, so there is no status and no ttfb.
           '-q', 'BereqMethod ne "PURGE" and VCL_call ne "PIPE"',
           '-F', '%m\t%s\t%{VSL:BackendOpen[2]}x\t%{Varnish:time_firstbyte}x']

    description = 'Varnish backend response time metric logger'
    key_prefix = 'varnish.backends'

    def __init__(self, argument_list):
        super(StatsdStatsSender, self).__init__(argument_list)
        self.buf = io.BytesIO()

    def handle_record(self, record):
        method, status_code, backend, ttfb = record.split('\t')

        # Stop here if ttfb is missing
        if len(ttfb) == 0:
            return

        ttfb = round(1000 * float(ttfb))
        backend = backend.split('.')[-1]

        fields = {
            'key_prefix': self.args.key_prefix,
            'method': method,
            'backend': backend,
            'status': status_code[0],
            'ttfb': ttfb
        }

        metric_string = (METRIC_FORMAT % fields).encode('utf-8')
        if self.buf.tell() + len(metric_string) >= UDP_MTU_BYTES:
            self.buf.seek(io.SEEK_SET)

            data = self.buf.read()

            if self.args.statsd_server:
                self.resolve_statsd_ip()
                self.sock.sendto(data, self.args.statsd_server)
            else:
                print(data.decode('utf-8', errors='replace').rstrip())

            self.buf = io.BytesIO()

        self.buf.write(metric_string)


if __name__ == "__main__":
    StatsdStatsSender(sys.argv[1:]).main()
