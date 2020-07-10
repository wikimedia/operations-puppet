#!/usr/bin/env python3

import os
import pwd
import logging
import sys
import subprocess
from enum import Enum

METRIC_PREFIX = "neutron_netns_"
OUTPUT_FILE = "/var/lib/prometheus/node.d/neutron_netns.prom"


class Keys(Enum):
    BUCKETS = "net.netfilter.nf_conntrack_buckets"
    COUNT = "net.netfilter.nf_conntrack_count"
    MAX = "net.netfilter.nf_conntrack_max"


def get_netns_dict():
    r = subprocess.run("ip netns list", shell=True, capture_output=True)
    if r.returncode != 0:
        logging.critical("failed to get netns list")
        sys.exit(1)

    if not r.stdout:
        logging.critical("no netns defined?")
        sys.exit(1)

    netns_dict = {}
    for netns_line in r.stdout.decode("utf-8").strip().splitlines():
        netns_id = netns_line.strip().split()[0]
        netns_dict[netns_id] = dict()
        for k in Keys:
            netns_dict[netns_id][k.value] = 0

    return netns_dict


def collect_values(netns_dict):
    for netns in netns_dict:
        for key in netns_dict[netns]:
            cmd = "ip netns exec {} sysctl {}".format(netns, key)
            r = subprocess.run(cmd, shell=True, capture_output=True)
            if r.returncode != 0:
                logging.critical("failed to exec cmd: {}".format(cmd))
                sys.exit(1)

            if not r.stdout:
                logging.critical("no output in cmd {}".format(cmd))
                sys.exit(1)

            netns_dict[netns][key] = r.stdout.decode("utf-8").strip().split()[2]


def dump_values(netns_dict):
    out = ""
    for netns in netns_dict:
        for key in netns_dict[netns]:
            metric_name = METRIC_PREFIX + key.split(".")[2]
            out = out + "{}{{netns=\"{}\",key=\"{}\"}} {}\n".format(
                metric_name, netns, key, netns_dict[netns][key]
            )

    f = open(OUTPUT_FILE, "w")
    f.write(out)
    f.close()
    os.chown(
        OUTPUT_FILE,
        pwd.getpwnam("prometheus").pw_uid,
        pwd.getpwnam("prometheus").pw_gid,
    )
    logging.info("metrics have been dumped to {}".format(OUTPUT_FILE))


def main():
    logging_format = "[%(filename)s] %(levelname)s: %(message)s"
    logging.basicConfig(format=logging_format, level=logging.INFO, stream=sys.stdout)

    if os.geteuid() != 0:
        logging.critical("root required!")
        sys.exit(1)

    netns_dict = get_netns_dict()
    collect_values(netns_dict)
    dump_values(netns_dict)


if __name__ == "__main__":
    main()
