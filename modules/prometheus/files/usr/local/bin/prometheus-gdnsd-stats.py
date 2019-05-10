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
import os.path
import subprocess
import json
import requests
import re

from prometheus_client import CollectorRegistry, Gauge, write_to_textfile
from prometheus_client.exposition import generate_latest

log = logging.getLogger(__name__)


# TODO(filippo) collect 'services' metrics
def collect_gdnsd_stats(stats, registry):
    dns_stats = {}
    udp_stats = {}
    tcp_stats = {}

    dns_stats['requests'] = Gauge(
        'request', 'Requests processed', ['status'],
        namespace='gdnsd', registry=registry)
    dns_stats['edns'] = Gauge(
        'request_edns', 'EDNS requests', namespace='gdnsd', registry=registry)
    dns_stats['edns_clientsub'] = Gauge(
        'request_edns_client_subnet', 'EDNS requests with client subnet',
        namespace='gdnsd', registry=registry)
    dns_stats['v6'] = Gauge(
        'request_v6', 'IPv6 requests', namespace='gdnsd', registry=registry)
    dns_stats['cookies'] = Gauge(
        'cookie', 'EDNS cookies processed', ['status'],
        namespace='gdnsd', registry=registry)

    if any(x not in stats for x in ('uptime', 'udp', 'tcp', 'stats')):
        raise ValueError('Failed to parse stats {}'.format(stats))

    cookie_re = re.compile('^edns_cookie_([a-z]+)$')
    try:
        for name, value in stats['stats'].items():
            cm = cookie_re.match(name)
            if cm:
                dns_stats['cookies'].labels(status=cm.group(1)).set(value)
            elif name in ('noerror', 'refused', 'nxdomain', 'notimp',
                          'badvers', 'formerr', 'dropped'):
                dns_stats['requests'].labels(status=name).set(value)
            elif name in dns_stats:
                dns_stats[name].set(value)
        for name, value in stats['udp'].items():
            udp_stats[name] = Gauge(
                'udp_{}'.format(name), 'UDP packets {}'.format(name),
                namespace='gdnsd', registry=registry)
            udp_stats[name].set(value)
        for name, value in stats['tcp'].items():
            tcp_stats[name] = Gauge(
                'tcp_{}'.format(name), 'TCP packets {}'.format(name),
                namespace='gdnsd', registry=registry)
            tcp_stats[name].set(value)
        uptime = Gauge(
            'uptime', 'gdnsd daemon uptime', namespace='gdnsd',
            registry=registry)
        uptime.set(stats['uptime'])
    except ValueError:
        log.exception('Failed to parse stats {}'.format(stats))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--outfile', metavar='FILE.prom',
                        help='Output file (stdout)')
    parser.add_argument('--url', metavar='URL',
                        help='gdnsd-2.x JSON URI (%(default)s)',
                        default='http://localhost:3506/json')
    parser.add_argument('--ctlpath', metavar='PATH',
                        help='gdnsd-3.x gdnsdctl path (%(default)s)',
                        default='/usr/bin/gdnsdctl')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debug logging (false)')
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)

    if args.outfile and not args.outfile.endswith('.prom'):
        parser.error('Output file does not end with .prom')

    if os.path.isfile(args.ctlpath):
        # gdnsd-3.x uses a CLI tool to dump JSON stats
        raw = subprocess.check_output([args.ctlpath, 'stats'])
        json_stats = json.loads(raw)
    else:
        # gdnsd-2.x uses HTTP and the url argument instead:
        try:
            response = requests.get(args.url, timeout=2)
            response.raise_for_status()
            json_stats = response.json()
        except (requests.exceptions.RequestException, ValueError):
            log.exception('Error fetching from {}'.format(args.url))
            return 1

    registry = CollectorRegistry()
    collect_gdnsd_stats(json_stats, registry)

    if args.outfile:
        write_to_textfile(args.outfile, registry)
    else:
        sys.stdout.write(generate_latest(registry).decode('utf-8'))


if __name__ == '__main__':
    sys.exit(main())
