#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""
Purpose: a script to check ferm/iptables's configured MSS value

What This Does:

    1. Takes in one or more IP address/port combinations and an optional filename
    2. Calls `/usr/sbin/iptables -L OUTPUT -nv` and/or `/usr/bin/ip6tables -L \
            OUTPUT -nv`
    3. Extracts the following from the ip[6]tables output:

        * TCP MSS clamp value
        * interface

    4. Inserts the above values into a dictionary that is written to either the
    file configured using the `-o` flag or `/var/lib/prometheus/node.d/\
            ferm-realserver-mss.prom` (default)

Example: `prometheus-ferm-mss.py -e $ENDPOINT [-e $ANOTHER_ENDPOINT] [-o $FILENAME]`
    $ENDPOINT is an IP address (can be v4 or v6) and port, which can be in one of
    the following formats:

      * v4: `$IP_ADDR:$PORT`
      * v6: `[$IP_ADDR]:$PORT`


"""

from argparse import ArgumentParser
from pathlib import Path
from typing import Dict, List
import re
import ipaddress
import sys
import subprocess
from prometheus_client import (
    CollectorRegistry,
    Gauge,
    write_to_textfile
)


def call_iptables(version=4) -> List[str]:
    opts = ["-L", "OUTPUT", "-n", "-v"]
    if version == 4:
        cmd = "/usr/sbin/iptables"
    elif version == 6:
        cmd = "/usr/sbin/ip6tables"
    else:
        raise ValueError(f"invalid version: {version}")
    result = subprocess.run([cmd, *opts], capture_output=True, text=True)
    try:
        result.check_returncode()
    except subprocess.CalledProcessError as e:
        print(f"Error calling {cmd}: {e}")
        raise
    return result.stdout.splitlines()


def process_output(iptables_txt: Dict[int, List[str]],
                   endpoints: Dict[int, List[str]]) -> Dict[int, Dict[str, Dict[str, int]]]:
    """This iterates over the ip[6]tables output and extracts the TCP MSS value as well as the
    interface for each IP:port combination. """
    tcp_mss_vals = {4: {}, 6: {}}
    for version, text in iptables_txt.items():
        for line in text:
            if not re.match("^\\d+", line.lstrip()):  # skip the headers
                continue
            try:
                fields = line.split(maxsplit=9)
            except Exception as e:
                print(f"error processing output from ip[6]tables: {e}")
                raise
            ip_addr = fields[7]
            if fields[2] != "TCPMSS":
                print(f"TCPMSS rule not present for {ip_addr}")
                continue
            port_match = re.match("tcp spt:(\\d+)", fields[9])  # port & clamp val in the last field
            tcp_mss_match = re.search("TCPMSS set (\\d+)$", fields[9])
            if not port_match:
                print(f"warning: unable to find port for {ip_addr}")
                continue
            if not tcp_mss_match:
                print(f"warning: unable to find TCPMSS value for {ip_addr}")
                continue
            port = port_match.group(1)
            tcp_mss_val = tcp_mss_match.group(1)
            iface = fields[6]
            endpoint_key = f"{ip_addr}:{port}"
            if endpoint_key in endpoints[version]:
                if iface in tcp_mss_vals[version]:
                    tcp_mss_vals[version][iface].update({endpoint_key: tcp_mss_val})
                else:
                    tcp_mss_vals[version].update({iface: {endpoint_key: tcp_mss_val}})
    return tcp_mss_vals


def process_ip_args(endpoints: List[str]) -> Dict[int, List[str]]:
    """Processes (see below) IP address/port pairs and inserts them into a mapping
    grouped by version (4|6)"""
    ip_addrs = {4: [], 6: []}
    for endpoint in endpoints:
        endpoint = endpoint.strip("'")
        ip, port = endpoint.rsplit(':', 1)
        ip = ip.strip("[]")  # only relevant to IPv6, but is essentially no-op for IPv4 addrs
        version = 0
        try:
            addr = ipaddress.ip_address(ip)
            version = addr.version
        except ValueError:
            print(f"Invalid IP: {ip}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Error: {e}")
            continue
        ip_addrs[version].append(f"{ip}:{port}")
    return ip_addrs


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-o',
                        '--outfile',
                        nargs='?',
                        type=Path,
                        default='/var/lib/prometheus/node.d/ferm-realserver-mss.prom')
    parser.add_argument('-e',
                        '--endpoint',
                        required=True,
                        type=ascii,
                        action='append',
                        help="ipv4:port or [ipv6]:port to check. It can be used multiple times")

    args = parser.parse_args()
    mss_vals = {4: {}, 6: {}}
    all_iptables_output = {4: [], 6: []}
    ip_addrs = process_ip_args(args.endpoint)
    if len(ip_addrs[6]) > 0:
        try:
            all_iptables_output[6] = call_iptables(6)
        except Exception as e:
            print(f"Error calling ip6tables: {e}")
            sys.exit(1)
    if len(ip_addrs[4]) > 0:
        try:
            all_iptables_output[4] = call_iptables(4)
        except Exception as e:
            print(f"Error calling iptables: {e}")
            sys.exit(1)
    try:
        mss_vals = process_output(all_iptables_output, ip_addrs)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
    registry = CollectorRegistry()
    gauge = Gauge('ferm_mss_cfg',
                  'MSS values for Ferm-based hosts',
                  ['interface', 'protocol', 'endpoint'], registry=registry)
    for version, ifaces in mss_vals.items():
        for iface, endpoint_tcpmss in ifaces.items():
            for endpoint, tcpmss in endpoint_tcpmss.items():
                endpoint_label = endpoint
                if version == 6:
                    ep_split = endpoint.rsplit(":", 1)
                    endpoint_label = f"[{ep_split[0]}]:{ep_split[1]}"
                gauge.labels(iface, f"IPv{version}", endpoint_label).set(float(tcpmss))
    write_to_textfile(args.outfile, registry)


if __name__ == '__main__':
    raise SystemExit(main())
