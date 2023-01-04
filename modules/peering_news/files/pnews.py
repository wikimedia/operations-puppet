#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Check PeeringDB for networks who recently joined the IXPs we're present in.

Works simply by comparing and old and a new netixlan JSON file.
To be used manually or with a systemd-timer that redirects the output to an email address.
If the `old_netixlan` file is stored in /tmp/ run it after a reboot.
API key only needed if used frequently (eg. multiple times an hour).
Define it with api_token_ro in YAML file.
"""

import argparse
import json

from pathlib import Path

from wmflib.config import load_yaml_config
from wmflib.requests import http_session

parser = argparse.ArgumentParser(description="What's new in our IXPs?")
parser.add_argument('--config', help='API-KEY file')
parser.add_argument('--proxy', help='HTTP and HTTPS proxy')
args = parser.parse_args()

netixlan_file = Path('/tmp/old_netixlan')
old_netixlan = None
if netixlan_file.exists():
    old_netixlan = json.loads(netixlan_file.read_text())
else:
    print("Old netixlan file not found, assuming first run.")

session = http_session('Peering News')

if args.config:
    config = load_yaml_config(args.config)
    token = config["api_token_ro"]
    session.headers.update({"Authorization": f"Api-Key {token}"})
if args.proxy:
    session.proxies = {"http": args.proxy, "https": args.proxy}

wikimedia_net_req = session.get('https://www.peeringdb.com/api/net/1365')

OUR_IXPS = [fac['ix_id'] for fac in wikimedia_net_req.json()['data'][0]['netixlan_set']
            if fac['operational']]

fresh_netixlan_req = session.get('https://www.peeringdb.com/api/netixlan')
fresh_netixlan = fresh_netixlan_req.json()
if old_netixlan:
    for router in fresh_netixlan['data']:
        if router['ix_id'] not in OUR_IXPS or not router['operational']:
            continue
        if router not in old_netixlan['data']:
            print(f"AS {router['asn']} added a router at {router['name']}",
                  f" (RS peer: {router['is_rs_peer']})",
                  f" - https://www.peeringdb.com/asn/{router['asn']}")

netixlan_file.write_text(json.dumps(fresh_netixlan))
