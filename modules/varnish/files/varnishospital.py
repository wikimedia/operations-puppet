#!/usr/bin/env python3
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

import sys

from wikimedia_varnishlogconsumer import BaseVarnishLogConsumer


class VarnishHospital(BaseVarnishLogConsumer):
    description = 'Varnish backend health logstash logger'

    def varnishlog_args(self):
        return [
            '-g', 'raw',
            # Query for "Back healthy" and "Went sick" events
            '-q', 'Backend_health ~ "Back healthy|Went sick"',
        ]

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

        0 Backend_health - vcl-588a49bd-7406-45ad-ae6e-a9fc9fbcc496.be_cp1075_wikimedia_org \
                Went sick ------- 2 3 5 0.000000 0.000435
        0 Backend_health - vcl-588a49bd-7406-45ad-ae6e-a9fc9fbcc496.be_cp1075_wikimedia_org \
                Back healthy 4--X-RH 3 3 5 0.000460 0.000494 HTTP/1.1 200 OK
        """
        splitline = line.split(None)

        vcl_id, origin_server = splitline[3].split('.')

        log = {
            'vcl_id': vcl_id,
            'origin_server': origin_server,
            'transition': "{} {}".format(splitline[4], splitline[5]),
            'window_bits': splitline[6],
            'good_probes': int(splitline[7]),
            'probe_threshold': int(splitline[8]),
            'probe_window_size': int(splitline[9]),
            'response_time': float(splitline[10]),
            'avg_response_time': float(splitline[11]),
            'http_response': " ".join(splitline[12:]),
            'layer': self.layer,
        }

        self.logger.info("{} {}".format(log['origin_server'], log['transition']), extra=log)


if __name__ == "__main__":
    VarnishHospital(sys.argv[1:]).main()
