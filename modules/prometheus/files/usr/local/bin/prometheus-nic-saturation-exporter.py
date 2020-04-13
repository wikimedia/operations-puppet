#!/usr/bin/env python3
"""
Polls network interface traffic second-by-second, then exports counters incremented whenever
the observed bandwidth in a sampling interval was 'too close' to line rate, indicating
saturation/congestion possibly occurred.
"""

__author__ = 'Chris Danis'
__version__ = '0.0.1'
__copyright__ = """
Copyright © 2020 Chris Danis & the Wikimedia Foundation

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
except in compliance with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the
License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied.  See the License for the specific language governing permissions
and limitations under the License.
"""

import argparse
import glob
import logging
import os
import time
from typing import Dict, Iterable

import attr
from prometheus_client import Counter, start_http_server

log = logging.getLogger(os.path.basename(__file__))

# All of our exported metrics have this prefix.
METRIC_NAMESPACE = 'nic_saturation'


@attr.s
class NICState:
    """A NICState is int counters for received bytes and transmitted bytes."""
    rx_bytes = attr.ib(type=int)
    tx_bytes = attr.ib(type=int)

    # NICStates can be subtracted from one another.
    def __sub__(self, other):
        return NICState(self.rx_bytes - other.rx_bytes,
                        self.tx_bytes - other.tx_bytes)


@attr.s
class State:
    """A State is an epoch timestamp, and a dictionary of {interface name: NICState}."""
    time = attr.ib(type=float)
    nicstates = attr.ib(type=Dict[str, NICState])


def read_sysfs(nic: str, file: str) -> str:
    """
    Reads a sysfs file corresponding to the given nic and file.
    The files read here are always single-line.
    """
    p = os.path.join('/sys/class/net', nic, file)
    with open(p, 'r') as f:
        return f.read().rstrip()


def read_state(nics: Iterable[str]) -> State:
    """
    Return a State for all interfaces named in nics.
    """
    log.debug('Scanning interfaces %s', nics)
    nicstates = {}
    for nic in nics:
        nicstates[nic] = NICState(rx_bytes=int(read_sysfs(nic, 'statistics/rx_bytes')),
                                  tx_bytes=int(read_sysfs(nic, 'statistics/tx_bytes')))
    return State(time=time.time(), nicstates=nicstates)


def get_nics() -> Iterable[str]:
    """
    Returns names of all NICs that are online and that have valid link speeds.
    """
    rv = []
    for p in glob.iglob('/sys/class/net/*/operstate'):
        nic = p.split('/')[4]
        try:
            if read_sysfs(nic, 'operstate') != 'up':
                log.debug('Skipping %s, interface is not up', nic)
                continue
            if int(read_sysfs(nic, 'speed')) == -1:
                # A -1 value means the kernel doesn't know the speed (wifi/virtual interface).
                log.debug('Skipping %s, cannot determine interface speed', nic)
                continue
        except OSError as e:
            log.debug('Skipping %s: %s', nic, e)
            continue
        rv.append(nic)
    return rv


def main(args):
    log.debug('Arguments: %s', args)
    log.info('Starting nic_saturation_exporter on port %d', args.port)
    start_http_server(args.port)

    # TODO: Would we ever want to support sampling intervals other than a second?
    # If so, we'd need different metric names, and probably to export the interval itself
    # as a gauge, so we can assign some physical meaning to the numbers.
    # TODO: Would it be useful to export the warm/hot thresholds as gauges?
    # TODO: Export a histogram of hotness percentiles? Would want to fine-grain the upper buckets.
    metrics = {
        'hot_seconds': Counter(
            'hot_seconds', 'Number of seconds a NIC was too hot', ['device', 'direction'],
            namespace=METRIC_NAMESPACE,
        ),
        'warm_seconds': Counter(
            'warm_seconds', 'Number of seconds a NIC was warm or hot', ['device', 'direction'],
            namespace=METRIC_NAMESPACE,
        )
    }

    thresholds = {'hot_seconds': args.hot, 'warm_seconds': args.warm}  # same keys as metrics

    state = read_state(args.nics or get_nics())
    log.debug('Initial state: %s', state)
    while True:
        time.sleep(1.0)
        # After sleeping, read the new NIC counters, and compute deltas.
        # Then compute (delta bytes/delta time)/(interface speed) to get a utilization fraction.
        # We do this for each NIC, and for each of rx and tx on said NIC.
        new_state = read_state(args.nics or get_nics())
        for nic in new_state.nicstates:
            if nic not in state.nicstates:
                continue
            try:
                speed_megabits = int(read_sysfs(nic, 'speed'))
                if speed_megabits == -1:
                    # A -1 value means the kernel doesn't know the speed (wifi/virtual interface).
                    continue
            except OSError as e:
                log.error('Couldn\'t read speed for %s: %s', nic, e)
                continue
            speed_bytes = speed_megabits * 1024 * 1024 / 8
            delta_bytes = new_state.nicstates[nic] - state.nicstates[nic]
            delta_time = new_state.time - state.time
            # Per https://prometheus.io/docs/practices/instrumentation/#avoid-missing-metrics
            # we want to make sure we're always exporting *some* value for a given NIC, even if
            # it is 0 since startup.  We implement this by incrementing counters by 0 or 1.
            for direction in ['rx', 'tx']:
                b = getattr(delta_bytes, '{}_bytes'.format(direction))
                percentage = 100 * (b/delta_time)/speed_bytes
                log.debug('%s %s %d bytes == %.2f%% utilization', nic, direction, b, percentage)
                for metric, threshold in thresholds.items():
                    metrics[metric].labels(device=nic, direction=direction).inc(
                        int(percentage >= threshold))
        state = new_state


if __name__ == '__main__':
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('nics', nargs='*', help='Interface names to poll, or none to autodetect')
    parser.add_argument('-p', '--port', help='Listen on this port', default=9710, type=int)
    parser.add_argument('--warm', help='Utilization percentage at which a NIC is considered warm.',
                        default=80, type=float)
    parser.add_argument('--hot', help='Utilization percentage at which a NIC is considered hot.',
                        default=90, type=float)
    parser.add_argument('-d', '--debug', action='store_true', help='Enable debug logging')
    parser.add_argument('--version', action='version', version='%(prog)s {}'.format(__version__))
    args = parser.parse_args()
    if not (0 < args.warm < 100):
        parser.error('--warm must be >0 and <100')
    if not (0 < args.hot <= 100):
        parser.error('--hot must be >0 and <=100')
    if args.warm >= args.hot:
        parser.error('--warm must be < --hot')
    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)
    main(args)
