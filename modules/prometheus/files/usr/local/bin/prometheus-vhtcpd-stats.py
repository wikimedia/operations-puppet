#!/usr/bin/python3
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
    # Metric documentation: https://phabricator.wikimedia.org/T249346#6026839
    #
    # Many of these are more properly counters than gauges, but the Prometheus
    # server is typeless & doesn't care -- Counter vs Gauge only affects the
    # client-side APIs (and Counter doesn't make .set() available).
    metrics = {
        'start': Gauge(
            'start', 'Start timestamp epoch seconds',
            namespace='vhtcpd', registry=registry),
        'uptime': Gauge(
            'uptime', 'Daemon uptime in seconds',
            namespace='vhtcpd', registry=registry),
        'input_packets_total': Gauge(
            'input_packets_total', 'Packets received by the shared listener',
            namespace='vhtcpd', registry=registry),
        'input_packets_bad_total': Gauge(
            'input_packets_bad_total',
            'Packets received by the shared listener that were somehow faulty',
            namespace='vhtcpd', registry=registry
        ),
        'input_packets_filtered_total': Gauge(
            'input_packets_filtered_total',
            'Packets received by the listener but filtered by configuration',
            namespace='vhtcpd', registry=registry
        ),
        'worker_input_packets_total': Gauge(
            'worker_input_packets_total',
            'Total packets enqueued on a given purger worker',
            ['worker'], namespace='vhtcpd', registry=registry
        ),
        'worker_input_packets_failed_total': Gauge(
            'worker_input_packets_failed_total',
            'Packets a given purger worker failed to deliver',
            ['worker'], namespace='vhtcpd', registry=registry
        ),
        'worker_queue_length': Gauge(
            'worker_queue_length',
            'Instantaneous queue size of each worker',
            ['worker'], namespace='vhtcpd', registry=registry
        ),
        'worker_queue_size_bytes': Gauge(
            'worker_queue_size_bytes',
            'Number of memory bytes consumed by each worker\'s queue',
            ['worker'], namespace='vhtcpd', registry=registry
        ),
    }

    # Maps vhtcpd output abbreviations to keys in the metrics dict.
    vhtcpd_output_to_metric = {
        # shared listener ('start:....') metrics
        'start': 'start',
        'uptime': 'uptime',
        'recvd': 'input_packets_total',
        'bad': 'input_packets_bad_total',
        'filtered': 'input_packets_filtered_total',
        # per-worker metrics
        'input': 'worker_input_packets_total',
        'failed': 'worker_input_packets_failed_total',
        'q_size': 'worker_queue_length',
        'q_mem': 'worker_queue_size_bytes',
    }

    def parse_metrics(stats, worker=None):
        for stat in stats:
            k, v = stat.split(':', 1)
            if k in vhtcpd_output_to_metric:
                m = vhtcpd_output_to_metric[k]
                try:
                    if worker:
                        metrics[m].labels(worker=worker).set(int(v))
                    else:
                        metrics[m].set(int(v))
                except ValueError as e:
                    log.warn('Error parsing %r: %r', stat, e)

    for line in infile.readlines():
        if line.startswith('start:'):
            stats = line.split(' ')
            parse_metrics(stats)
        else:
            worker, rest = line.split(': ', 1)
            stats = rest.split(' ')
            parse_metrics(stats, worker=worker)


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
        sys.stdout.buffer.write(generate_latest(registry))


if __name__ == "__main__":
    sys.exit(main())
