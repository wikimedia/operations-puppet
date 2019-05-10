#!/usr/bin/python
# Copyright 2016 Filippo Giunchedi
#                Wikimedia Foundation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import logging
import sys

from prometheus_client import CollectorRegistry, Gauge, write_to_textfile
from prometheus_client.exposition import generate_latest

log = logging.getLogger(__name__)


def collect_vhtcp_stats(infile, registry):
    metrics = {
        'start': Gauge(
            'start', 'Start timestamp', namespace='vhtcpd', registry=registry),
        'uptime': Gauge(
            'uptime', 'Daemon uptime', namespace='vhtcpd', registry=registry),
        'inpkts_recvd': Gauge(
            'inpkts_recvd', 'Packets received', namespace='vhtcpd',
            registry=registry),
        'inpkts_sane': Gauge(
            'inpkts_sane', 'Packets received and correct', namespace='vhtcpd',
            registry=registry),
        'inpkts_enqueued': Gauge(
            'inpkts_enqueued',
            'Packets received and made it to the send queue',
            namespace='vhtcpd', registry=registry),
        'inpkts_dequeued': Gauge(
            'inpkts_dequeued',
            'Packets sent as TCP PURGE to all applicable varnish instances',
            namespace='vhtcpd', registry=registry),
        'queue_overflows': Gauge(
            'queue_overflows',
            'How many times the queue was overflowed', namespace='vhtcpd',
            registry=registry),
        'queue_size': Gauge(
            'queue_size',
            'Number of packets in the queue',
            namespace='vhtcpd', registry=registry),
        'queue_max_size': Gauge(
            'queue_max_size',
            'Maximum number packets in the queue since start/overflow',
            namespace='vhtcpd', registry=registry),
    }

    stats = infile.readlines()[0].split(' ')
    for stat in stats:
        k, v = stat.split(':', 1)
        if k in metrics:
            try:
                metrics[k].set(int(v))
            except ValueError as e:
                log.warn('Error parsing %r: %r', stat, e)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--outfile', metavar='FILE.prom',
                        help='Output file (stdout)')
    parser.add_argument('--statsfile', metavar='FILE',
                        help='vhtcpd stats file (%(default)s)',
                        default='/tmp/vhtcpd.stats')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debug logging (false)')
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    if args.outfile and not args.outfile.endswith('.prom'):
        parser.error('Output file does not end with .prom')

    if args.statsfile:
        if args.statsfile == '-':
            infile = sys.stdin
        else:
            infile = open(args.statsfile, 'r')

    registry = CollectorRegistry()
    collect_vhtcp_stats(infile, registry)

    if args.outfile:
        write_to_textfile(args.outfile, registry)
    else:
        sys.stdout.write(generate_latest(registry))


if __name__ == "__main__":
    sys.exit(main())
