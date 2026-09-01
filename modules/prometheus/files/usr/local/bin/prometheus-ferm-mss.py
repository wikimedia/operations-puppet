#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""
Purpose: a script to check ferm/iptables's configured MSS value

What This Does:

    1. Takes in one or more IP address/port combinations and an optional filename
    2. Calls `/usr/sbin/iptables-save -t` and/or `/usr/bin/ip6tables-save -t`
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


def call_iptables_save(version=4) -> List[str]:
    opts = ["-t", "filter"]
    if version == 4:
        cmd = "/usr/sbin/iptables-save"
    elif version == 6:
        cmd = "/usr/sbin/ip6tables-save"
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
    """This iterates over the ip[6]tables-save output and extracts the TCP MSS value as well as the
    interface for each IP:port combination.
    Format: -A OUTPUT -s 208.80.154.242/32 -o ens1f0np0 -p tcp -m tcp --sport 2049\
            --tcp-flags SYN SYN -j TCPMSS --set-mss 1440"""
    tcp_mss_vals = {4: {}, 6: {}}
    chain_pattern = "-A OUTPUT"
    ip6_pattern = "-s ([a-f0-9:]+)"
    ip4_pattern = "-s ([0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3})"
    source_port_pattern = "--sport ([0-9]+)"
    mss_pattern = "--set-mss ([0-9]+)"
    iface_pattern = "-o ([a-z0-9]+)"
    for version, text in iptables_txt.items():
        ip_addr_pattern = ""
        if version == 4:
            ip_addr_pattern = ip4_pattern
        else:
            ip_addr_pattern = ip6_pattern
        for line in text:
            if not re.match(chain_pattern, line.lstrip()):  # skip all but the OUTPUT chain
                continue
            ip_pattern_match = re.search(ip_addr_pattern, line)
            if not ip_pattern_match:
                continue
            ip_addr = ip_pattern_match.group(1)
            mss_match = re.search(mss_pattern, line)
            if not mss_match:
                print(f"warning: unable to find MSS value for {ip_addr}")
                continue
            tcp_mss_val = mss_match.group(1)
            port_match = re.search(source_port_pattern, line)
            if not port_match:
                print(f"warning: unable to find port for {ip_addr}")
                continue
            port = port_match.group(1)
            iface_match = re.search(iface_pattern, line)
            if not iface_match:
                print(f"warning: unable to find iface for {ip_addr}")
                continue
            iface = iface_match.group(1)
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
        ip = ip.strip("[]")  # only relevant to IPv6
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
            all_iptables_output[6] = call_iptables_save(6)
        except Exception as e:
            print(f"Error calling ip6tables: {e}")
            sys.exit(1)
    if len(ip_addrs[4]) > 0:
        try:
            all_iptables_output[4] = call_iptables_save(4)
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
