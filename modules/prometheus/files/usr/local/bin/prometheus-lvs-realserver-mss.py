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

from pyroute2 import NDB

from scapy.all import (
    IP,
    IPv6,
    L3RawSocket,
    L3RawSocket6,
    TCP,
    sr1
)
from scapy.all import conf as scapyconf
scapyconf.use_pcap = False


# https://github.com/secdev/scapy/issues/4201
def fix_scapy_ipv4_route_table(ip: str) -> None:
    ndb = NDB()

    # RecordSet count() method isn't available on pyroute2 0.5.14 (bullseye)
    # if ndb.routes.summary().filter(dst=ip).count() == 0:
    if not any(ndb.routes.summary().filter(dst=ip)):
        # No route on the local routing table for the specified IP
        return None

    scapyconf.route.add(host=ip, gw='0.0.0.0', dev='lo')


def get_mss(host: str, port: int, version: int) -> Optional[int]:
    if version == 4:
        scapyconf.L3socket = L3RawSocket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.bind(("0.0.0.0", 0))
    else:
        scapyconf.L3socket = L3RawSocket6
        s = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
        s.bind(("::", 0))

    sport = s.getsockname()[1]

    if version == 4:
        syn_packet = IP(dst=host)/TCP(sport=sport, dport=port, flags="S", seq=1000)
    else:
        syn_packet = IPv6(dst=host)/TCP(sport=sport, dport=port, flags="S", seq=1000)
    synack = sr1(syn_packet, timeout=3, verbose=0)
    s.close()

    if synack is None or synack[TCP] is None:
        print(f"[!] Unexpected answer: {synack}", file=sys.stderr)
        return None

    for option in synack[TCP].options:
        if option[0] == 'MSS':
            return option[1]

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

        if version == 4:
            fix_scapy_ipv4_route_table(ip)

        mss = get_mss(ip, int(port), version)
        if mss is not None:
            gauge.labels(endpoint, f'IPv{version}').set(mss)
            success_gauge.labels(endpoint, f'IPv{version}').set(1)
        else:
            gauge.labels(endpoint, f'IPv{version}').set(0)
            success_gauge.labels(endpoint, f'IPv{version}').set(0)

    write_to_textfile(args.outfile, registry)
