#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# flake8: noqa: E501

"""
Purpose: a script to check nftables's configured MSS value

What This Does:

    1. Accepts an optional output filename to use
    2. Calls '/usr/sbin/nft --json list chain inet base output'
    3. For each rule that sets MSS, and matches on an interface, source \
       address and source port, parses these values.
    4. Inserts the above values into a dictionary that is written to either the
       file configured using the `-o` flag or `/var/lib/prometheus/node.d/\
            nftables-mss.prom` (default)

Example: `prometheus-nftables-mss.py [-o $FILENAME]`

"""

from argparse import ArgumentParser
import json
from pathlib import Path
from typing import Dict
import subprocess
from prometheus_client import (
    CollectorRegistry,
    Gauge,
    write_to_textfile
)


def run_nftables_cmd() -> Dict:
    cmd = ["/usr/sbin/nft", "--json", "list", "chain", "inet", "base", "output"]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    try:
        result.check_returncode()
    except subprocess.CalledProcessError as e:
        print(f"Error calling {cmd}: {e}")
        raise
    return json.loads(result.stdout)


def parse_nft_rule(rule) -> Dict:
    """Parses list of elements from NFT rule, expected input is a list of dicts with this format:
         [
           {'match': {'left': {'meta': {'key': 'oifname'}}, 'op': '==', 'right': 'lo'}},
           {'match': {'left': {'payload': {'field': 'saddr', 'protocol': 'ip'}}, 'op': '==', 'right': '2.3.4.5'}},
           {'match': {'left': {'payload': {'field': 'sport', 'protocol': 'tcp'}}, 'op': '==', 'right': 200}},
           {'match': {'left': {'payload': {'field': 'flags', 'protocol': 'tcp'}}, 'op': 'in', 'right': 'syn'}},
           {'mangle': {'key': {'tcp option': {'field': 'size', 'name': 'maxseg'}}, 'value': 1400}}
         ]
    """
    interface = None
    saddr = None
    sport = None
    mss = None
    for element in rule:
        try:
            if "match" in element and element["match"]["op"] == "==":
                if "meta" in element["match"]["left"]:
                    if element["match"]["left"]["meta"]["key"] == "oifname":
                        interface = element["match"]["right"]
                elif "payload" in element["match"]["left"]:
                    if element["match"]["left"]["payload"]["field"] == "saddr":
                        protocol = element["match"]["left"]["payload"]["protocol"]
                        saddr = element["match"]["right"]
                    elif element["match"]["left"]["payload"]["field"] == "sport":
                        sport = element["match"]["right"]
            elif "mangle" in element:
                if "tcp option" in element["mangle"]["key"]:
                    if element["mangle"]["key"]["tcp option"]["name"] == "maxseg":
                        mss = element["mangle"]["value"]
        except KeyError:
            # shouldn't happen, but cover scenario where element has unexpected structure
            continue

    if interface and saddr and sport and mss:
        if protocol == "ip":
            ip_ver = "IPv4"
            endpoint = f"{saddr}:{sport}"
        else:
            ip_ver = "IPv6"
            endpoint = f"[{saddr}]:{sport}"
        return {"interface": interface, "ip_ver": ip_ver, "endpoint": endpoint, "mss": float(mss)}
    else:
        return {}


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("-o",
                        "--outfile",
                        nargs='?',
                        type=Path,
                        default='/var/lib/prometheus/node.d/nftables-mss.prom')
    args = parser.parse_args()

    # Set up prometheus output
    registry = CollectorRegistry()
    # TODO: keeping original gauge name for backwards compatibility with monitoring
    gauge = Gauge("ferm_mss_cfg",
                  "MSS values for ferm or nftables based hosts",
                  ["interface", "protocol", "endpoint"], registry=registry)

    output_chain_rules = run_nftables_cmd()
    for nftables_element in output_chain_rules['nftables']:
        if "rule" not in nftables_element:
            continue
        rule = parse_nft_rule(nftables_element['rule']['expr'])
        if rule:
            gauge.labels(rule["interface"], rule["ip_ver"], rule["endpoint"]).set(rule["mss"])
    write_to_textfile(args.outfile, registry)


if __name__ == '__main__':
    raise SystemExit(main())
