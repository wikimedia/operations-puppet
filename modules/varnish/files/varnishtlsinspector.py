#!/usr/bin/env python3
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
import sys

from wikimedia_varnishlogconsumer import BaseVarnishLogConsumer


class VarnishTLSInpector(BaseVarnishLogConsumer):
    description = 'Varnish TLS ciphersuites logstash logger'

    def varnishlog_args(self):
        query = [
            'ReqMethod ne PURGE',
            'ReqHeader:X-Forwarded-Proto eq https',
            'ReqHeader:X-CP-Key-Exchange eq RSA',
        ]

        return [
            # Query for HTTPS requests using RSA key exchange
            '-q', ' and '.join(query),
            # Set maximum Varnish transaction duration to track
            '-T', '%d' % self.args.transaction_timeout,
        ]

    def handle_tag(self, tag, value):
        if tag == 'VCL_Log':
            splitagain = value.split(None, 1)
            log_name = splitagain[0][:-1]

            if log_name in ['CP-TLS-Version', 'CP-Key-Exchange',
                            'CP-Auth', 'CP-Cipher', 'CP-Full-Cipher']:
                if len(splitagain) == 2:
                    log_value = splitagain[1]
                else:
                    log_value = ''

                self.tx['log-' + log_name] = log_value

    def handle_end(self):
        if 'request-User-Agent' in self.tx and 'log-CP-Full-Cipher' in self.tx:
            self.logger.info(self.tx['log-CP-Full-Cipher'] + self.tx['request-User-Agent'],
                             extra=self.tx)


if __name__ == "__main__":
    VarnishTLSInpector(sys.argv[1:]).main()
