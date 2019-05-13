#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Reads varnish shared logs and emits counts for the following:
  - Total requests
  - HTTP Status Code (200, 404, etc.)
  - HTTP Status Code Class (2xx, 3xx, etc.)
  - HTTP Status type (ok, error)
  - HTTP Method (GET, POST, etc.)

  Copyright 2015-2016 Andrew Otto <otto@wikimedia.org>
                 2016 Emanuele Rocca <ema@wikimedia.org>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  Author: Andrew Otto

"""
import sys

from cachestats import CacheStatsSender


class ReqStatsSender(CacheStatsSender):
    cmd = ['/usr/bin/varnishncsa', '-n', 'frontend',
           '-b', '-c',
           # remote_party - method - status
           '-F', '%{Varnish:side}x\t%m\t%s']

    description = __doc__
    key_prefix = 'varnish'
    default_keys = (
        'backend.status.1xx',
        'backend.status.2xx',
        'backend.status.3xx',
        'backend.status.4xx',
        'backend.status.5xx',
        'backend.status.ok',
        'backend.status.error',
        'backend.total',

        'client.status.1xx',
        'client.status.2xx',
        'client.status.3xx',
        'client.status.4xx',
        'client.status.5xx',
        'client.status.ok',
        'client.status.error',
        'client.total',
    )
    valid_http_methods = (
        'get',
        'head',
        'post',
        'put',
        'delete',
        'trace',
        'connect',
        'options',
        'purge',
    )

    def __init__(self, argument_list):
        valid_methods_metrics = []
        for method in self.valid_http_methods:
            valid_methods_metrics.append('backend.method.' + method)
            valid_methods_metrics.append('client.method.' + method)
        self.default_keys = self.default_keys + tuple(valid_methods_metrics)

        super(ReqStatsSender, self).__init__(argument_list)

    def is_valid_http_method(self, method):
        return method.lower() in self.valid_http_methods

    def gen_stats(self, record):
        remote_party, method, status_code = record.split('\t')

        if not status_code.isdigit():
            return

        if remote_party == 'b':
            remote_party = 'backend'
        elif remote_party == 'c':
            remote_party = 'client'
        else:
            return

        if not self.is_valid_http_method(method):
            return

        self.stats[remote_party + '.method.' + method.lower()] += 1
        key_prefix = remote_party + '.status.'

        self.stats[key_prefix + status_code[0] + 'xx'] += 1

        http_status_key = key_prefix + status_code

        self.stats[http_status_key] = (
            self.stats.setdefault(http_status_key, 0) + 1
        )

        # Increment ok/error status metric.
        if status_code[0] in '123':
            self.stats[key_prefix + 'ok'] += 1
        elif status_code[0] in '45':
            self.stats[key_prefix + 'error'] += 1

        self.stats[remote_party + '.total'] += 1


if __name__ == "__main__":
    ReqStatsSender(sys.argv[1:]).main()
