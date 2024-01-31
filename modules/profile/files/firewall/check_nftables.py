#! /usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Prometheus gauge to check for a running nftables."""

import argparse
import os
import subprocess
import sys

PROM_BLOB = ("# HELP firewall_running Is the configured firewall running\n"
             "# TYPE firewall_running gauge\n"
             'firewall_running{policy="drop"} ')


def write_prom_file(state, filepath):
    with open(filepath, 'w') as f:
        f.write(PROM_BLOB + state + "\n")
    sys.exit(0)


def main():
    if os.geteuid() != 0:
        print("script needs to be run as root")
        sys.exit(1)

    parser = argparse.ArgumentParser()
    parser.add_argument('--outfile',
                        default='/var/lib/prometheus/node.d/firewall-running.prom',
                        help='Output file to write to')
    args = parser.parse_args()

    nft_cmd = '/usr/sbin/nft list chain inet base input'

    try:
        nft_ruleset = subprocess.check_output(nft_cmd.split(),
                                              universal_newlines=True,
                                              stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        write_prom_file("0.0", args.outfile)
        return

    for rule in nft_ruleset.split("\n"):
        if rule.find('policy drop;') != -1:
            write_prom_file("1.0", args.outfile)

    write_prom_file("0.0", args.outfile)


if __name__ == "__main__":
    main()
