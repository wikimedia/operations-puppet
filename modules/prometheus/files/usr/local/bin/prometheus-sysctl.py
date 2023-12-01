#!/usr/bin/python3
#
# SPDX-License-Identifier: Apache-2.0
#
# Usage: prometheus-sysctl [outfile]
#
# Some sysctl values are still not exported in prometheus' node_exporter (e.g.
# sys/vm). Once support is enabled this can be removed but until then we need
# to export it ourselves.
import argparse
import subprocess
import sys

from abc import ABC, abstractmethod
from pathlib import Path
from typing import Optional

from prometheus_client import (
    CollectorRegistry,
    Gauge,
    write_to_textfile
)


# refactor with typing.Protocol after we have python >3.9.7 available
# (https://bugs.python.org/issue45121)
class Sysctl(ABC):
    @abstractmethod
    def handle(self, key: str, value: str) -> None:
        pass


class GenericSysctl(Sysctl):
    """Generic sysctl handling. Attempts to produce
       valid metric names replacing "." and "-" with "_"
       """
    def __init__(self, registry: CollectorRegistry):
        self.registry = registry

    def handle(self, key: str, value: str) -> None:
        metric_name = f"sysctl_{key.replace('.', '_').replace('-', '_')}"
        g = Gauge(metric_name, f'sysctl {key}', registry=self.registry)
        g.set(value)


class RpFilterSysctl(Sysctl):
    """Handle net.ipv4.conf.<interface>.rp_filter sysctls.
       Sets an interface label for each interface detected.
       "all" and "default" are also reported as interfaces
    """
    __gauge = None

    def __init__(self, registry: CollectorRegistry):
        if RpFilterSysctl.__gauge is None:
            RpFilterSysctl.__gauge = Gauge('sysctl_net_ipv4_conf_rp_filter',
                                           'sysctl net.ipv4_conf.<interface>.rp_filter',
                                           ['interface'], registry=registry)

    def handle(self, key: str, value: str) -> None:
        interface_name = key.split('.')[-2]
        RpFilterSysctl.__gauge.labels(interface_name).set(value)


# sysctls to fetch
SYSCTLS = {
        'vm.max_map_count': {'filter': None, 'class': GenericSysctl},
        'net.ipv4.conf': {'filter': '.rp_filter', 'class': RpFilterSysctl},
}


def fetch_sysctl(sysctl: str, string_filter: str = None) -> Optional[dict]:
    sysctl_run = subprocess.run(["/usr/sbin/sysctl", "--", sysctl], capture_output=True, text=True)
    if sysctl_run.returncode > 0:
        print(f'Unexpected sysctl returncode: {sysctl_run.returncode}', file=sys.stderr)
        return None

    ret = {}
    for line in sysctl_run.stdout.splitlines():
        try:
            key, value = line.split('=')
            if string_filter is not None and string_filter not in key:
                continue
            ret[key.strip()] = value.strip()
        except ValueError:
            continue

    return ret


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('outfile',
                        nargs='?',
                        type=Path,
                        default='/var/lib/prometheus/node.d/sysctl.prom')

    args = parser.parse_args()

    registry = CollectorRegistry()

    for sysctl, sysctl_config in SYSCTLS.items():
        data = fetch_sysctl(sysctl, sysctl_config['filter'])
        if data is None:
            print(f'Unable to fetch {sysctl}', file=sys.stderr)
            continue

        for key, value in data.items():
            s = sysctl_config['class'](registry)
            s.handle(key, value)

    # write_to_textfile already creates a temporary file that is renamed
    # to the specified path after writing all the contents
    write_to_textfile(args.outfile, registry)
