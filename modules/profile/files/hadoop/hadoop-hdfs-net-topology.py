#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

# NOTE: This file is managed by Puppet.

# Returns a rack/row name for the given node name.

# Usage:
#   net-topology.py <ipaddr|fqdn>

import argparse
import configparser
import os
import socket
import sys


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='net-topology',
        description='Returns the rack/row for a given Hadoop node',
    )

    parser.add_argument('-c', '--config', required=True, help='Path to configuration file')
    parser.add_argument('node', nargs='*')
    args = parser.parse_args()

    if not os.path.isfile(args.config):
        print('configuration file not found')
        sys.exit(1)

    config = configparser.ConfigParser()
    config.read(args.config)
    site = config.get('DEFAULT', 'site')
    nodes = config['nodes']

    if not args.node:
        print(f'/{site}/default/rack')

    for node in args.node:
        if node in nodes:
            print(nodes.get(node))
        else:
            print(nodes.get(socket.getfqdn(node), f'/{site}/default/rack'))
