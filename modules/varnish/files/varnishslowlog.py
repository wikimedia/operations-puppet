#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  VarnishSlowLog
  ~~~~~~~~~~~~~~
  VarnishSlowLog is responsible for gathering slow requests from varnishlog
  and sending them to logstash.

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

import sys

from varnishlogconsumer import VarnishLogConsumer


class VarnishSlowLog(VarnishLogConsumer):
    description = 'Varnish slow log logstash logger'

    def varnishlog_args(self):
        # Note slow 'Resp' is not included in the filter, as normal requests
        # with slow true-client-side reception can raise this value throughout
        # the stack, even in backends the request is passing through, as the
        # response will only stream through them at the rate necessary to feed
        # the fastest (possibly only) requesting parallel client.  Thus it
        # generates too much slowlog noise, making it harder to spot the "real"
        # problems.
        tstypes = ('Start', 'Req', 'ReqBody', 'Waitinglist',
                   'Fetch', 'Process', 'Restart')

        # Build VSL query to find non-PURGEs with any
        # timestamp > slow_threshold
        timestamps = [
            'Timestamp:%s[3] > %f' % (timestamp, self.args.slow_threshold)
            for timestamp in tstypes
        ]

        query = 'ReqMethod ne "PURGE" and (%s)' % " or ".join(timestamps)

        return ['-q', query, '-T', '%d' % self.args.transaction_timeout]

    def add_cmd_args(self):
        return [
            (['--slow-threshold'],
                {'help': 'varnish slow timing threshold',
                    'type': float, 'default': 10.0})
        ]

    def handle_end(self):
        if 'request-Host' in self.tx and 'http-url' in self.tx:
            self.logger.info(
                self.tx['request-Host'] + self.tx['http-url'], extra=self.tx
            )


if __name__ == "__main__":
    VarnishSlowLog(sys.argv[1:]).main()
