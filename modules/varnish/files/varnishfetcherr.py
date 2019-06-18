#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
  VarnishFetchErr
  ~~~~~~~~~~~~~~~
  VarnishFetchErr is responsible for gathering backend requests resulting in a
  FetchError and sending them to logstash.

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

import sys

from wikimedia_varnishlogconsumer import BaseVarnishLogConsumer


class VarnishFetchErr(BaseVarnishLogConsumer):
    description = "Varnish fetch error logstash logger"

    def varnishlog_args(self):
        return [
            "-g", "request",
            "-b",
            "-q", 'FetchError ne "Pass delivery abandoned"',
            "-T", "%d" % self.args.transaction_timeout,
        ]

    def handle_end(self):
        if "fetcherror" in self.tx and "http-url" in self.tx:
            self.logger.info(
                "%s %s", self.tx["fetcherror"], self.tx["http-url"], extra=self.tx
            )

    def handle_tag(self, tag, value):
        if tag.startswith("Backend") or tag in ["HttpGarbage", "FetchError"]:
            self.tx[tag.lower()] = value


if __name__ == "__main__":
    VarnishFetchErr(sys.argv[1:]).main()
