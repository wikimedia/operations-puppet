#!/usr/bin/env python3

# NOTE for the future: if we allow users to create arbitrary neutron routers
# this could mean we could get paged by user-controlled routers being full.

import argparse
import os
import logging
import sys
import subprocess
from enum import Enum

# alert when the table is over MAGIC_VALUE percentage full
MAGIC_VALUE = 90


class Keys(Enum):
    COUNT = "net.netfilter.nf_conntrack_count"
    MAX = "net.netfilter.nf_conntrack_max"


def alert_and_exit(message):
    logging.critical("CRITICAL: {}".format(message))
    sys.exit(2)


def get_netns_dict():
    r = subprocess.run("ip netns list", shell=True, capture_output=True)
    if r.returncode != 0:
        alert_and_exit("failed to get netns list")

    if not r.stdout:
        alert_and_exit("no netns defined?")

    netns_dict = {}
    for netns_line in r.stdout.decode("utf-8").strip().splitlines():
        netns_id = netns_line.strip().split()[0]
        netns_dict[netns_id] = dict()
        logging.debug("DEBUG: detected netns {}".format(netns_id))
        for k in Keys:
            netns_dict[netns_id][k] = 0

    return netns_dict


def collect_values(netns_dict):
    for netns in netns_dict:
        for key in netns_dict[netns]:
            cmd = "ip netns exec {} sysctl {}".format(netns, Keys(key).value)
            r = subprocess.run(cmd, shell=True, capture_output=True)
            if r.returncode != 0:
                alert_and_exit("failed to exec cmd: {}".format(cmd))

            if not r.stdout:
                alert_and_exit("no output in cmd {}".format(cmd))

            netns_dict[netns][key] = r.stdout.decode("utf-8").strip().split()[2]
            logging.debug(
                "DEBUG: {} {} {}".format(netns, key.value, netns_dict[netns][key])
            )


def evaluate_values(netns_dict):
    for netns in netns_dict:
        # for now, only interested in qrouter-* namespaces
        if "qrouter-" not in netns:
            logging.debug("DEBUG: not evaluating netns {}".format(netns))
            continue

        usage = (
            int(netns_dict[netns][Keys.COUNT]) * 100 / int(netns_dict[netns][Keys.MAX])
        )
        logging.debug("DEBUG: {}% usage in netns {}".format(usage, netns))

        if usage > MAGIC_VALUE:
            alert_and_exit(
                "nf_conntrack usage over {}% in netns {}".format(MAGIC_VALUE, netns)
            )


def main():
    parser = argparse.ArgumentParser(
        description="NRPE check for neutron nf_conntrack values"
    )
    parser.add_argument("-d", "--debug", action="store_true", help="enable debug mode")
    args = parser.parse_args()

    logging_format = "%(message)s"
    logging_level = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(format=logging_format, level=logging_level, stream=sys.stdout)

    if os.geteuid() != 0:
        alert_and_exit("root required!")

    logging.debug("DEBUG: magic usage value is {}% (hardcoded)".format(MAGIC_VALUE))
    netns_dict = get_netns_dict()
    collect_values(netns_dict)
    evaluate_values(netns_dict)

    # script didn't end yet, we are good!
    logging.info("OK: everything is apparently fine")


if __name__ == "__main__":
    main()
