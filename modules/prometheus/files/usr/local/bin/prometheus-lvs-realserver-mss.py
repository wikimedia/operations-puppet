#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import argparse
import ipaddress
import socket
import sys

from pathlib import Path
from typing import Optional

from prometheus_client import (
    CollectorRegistry,
    Gauge,
    write_to_textfile
)

try:
    TCP_REPAIR = socket.TCP_REPAIR
except AttributeError:  # only available on python 3.12+
    TCP_REPAIR = 19


def get_mss(host: str, port: int, version: int) -> Optional[int]:
    if version == 4:
        family = socket.AF_INET
    else:
        family = socket.AF_INET6

    s = socket.socket(family, socket.SOCK_STREAM)
    s.settimeout(3)
    try:
        s.connect((host, port))
        # enable TCP_REPAIR to be able to access on-the-wire MSS
        s.setsockopt(socket.IPPROTO_TCP, TCP_REPAIR, 1)
        max_seg = s.getsockopt(socket.IPPROTO_TCP, socket.TCP_MAXSEG)
        # disable it to get a clean close
        s.setsockopt(socket.IPPROTO_TCP, TCP_REPAIR, 0)
        s.close()
        return max_seg
    except (TimeoutError, OSError):
        return None


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-o',
                        '--outfile',
                        nargs='?',
                        type=Path,
                        default='/var/lib/prometheus/node.d/realserver-mss.prom')
    parser.add_argument('-e',
                        '--endpoint',
                        required=True,
                        type=ascii,
                        action='append',
                        help="ipv4:port or [ipv6]:port to check. It can be used multiple times")

    args = parser.parse_args()

    registry = CollectorRegistry()
    gauge = Gauge('lvs_realserver_mss_value',
                  'MSS values', ['endpoint', 'protocol'], registry=registry)
    success_gauge = Gauge('lvs_realserver_mss_successful_measurement',
                          'Reports whether the last measurement has been successful or not',
                          ['endpoint', 'protocol'], registry=registry)
    results = {}

    for endpoint in args.endpoint:
        endpoint = endpoint.strip("'")
        ip, port = endpoint.rsplit(':', 1)
        ip = ip.strip('[]')  # ipaddress would reject an IPv6 wrapped with square brackets
        version = 0
        try:
            ipa = ipaddress.ip_address(ip)
            version = ipa.version
        except ValueError:
            print(f'Invalid IP: {ip}', file=sys.stderr)
            sys.exit(1)

        mss = get_mss(ip, int(port), version)
        if mss is not None:
            gauge.labels(endpoint, f'IPv{version}').set(mss)
            success_gauge.labels(endpoint, f'IPv{version}').set(1)
        else:
            gauge.labels(endpoint, f'IPv{version}').set(0)
            success_gauge.labels(endpoint, f'IPv{version}').set(0)

    write_to_textfile(args.outfile, registry)
