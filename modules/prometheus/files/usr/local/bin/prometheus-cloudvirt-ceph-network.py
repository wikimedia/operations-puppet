#!/usr/bin/env python3

import os
import pwd
import logging
import sys
import subprocess
import ipaddress

METRIC_PREFIX = "cloudvirt_ceph_network_"
OUTPUT_FILE = "/var/lib/prometheus/node.d/cloudvirt_ceph_network.prom"
CEPH_CONFIG_FILE = "/etc/ceph/ceph.conf"


def get_ceph_servers_dict():
    ceph_servers_dict = {}
    try:
        f = open(CEPH_CONFIG_FILE, "r")
    except FileNotFoundError as e:
        logging.critical("Could not parse ceph servers: {}".format(e))
        sys.exit(1)

    for line in f.readlines():
        if line.strip().startswith("mon addr"):
            addr = line.split()[3]
            try:
                ipaddress.IPv4Interface(addr)
            except ValueError as e:
                logging.critical(
                    "Could not parse ceph servers, malformed address: {}".format(e)
                )
                f.close()
                sys.exit(1)

            ceph_servers_dict[addr] = {}
            ceph_servers_dict[addr]["bytes_sent"] = 0
            ceph_servers_dict[addr]["bytes_received"] = 0

    f.close()
    return ceph_servers_dict


def collect_values(ceph_servers_dict):
    for ceph_server in ceph_servers_dict:
        cmd = "ss -Htni dst {}".format(ceph_server)
        r = subprocess.run(cmd, shell=True, capture_output=True)
        if r.returncode != 0:
            logging.critical("failed to exec cmd: {}".format(cmd))
            sys.exit(1)

        if not r.stdout:
            # no connection to this ceph server?
            continue

        for line in r.stdout.decode("utf-8").strip().split():
            if line.startswith("bytes_sent:"):
                number = int(line.split(":")[1])
                ceph_servers_dict[ceph_server]["bytes_sent"] += number

            if line.startswith("bytes_received:"):
                number = int(line.split(":")[1])
                ceph_servers_dict[ceph_server]["bytes_received"] += number

    return ceph_servers_dict


def dump_values(ceph_servers_dict):
    out = ""
    for ceph_server in ceph_servers_dict:
        for key in ceph_servers_dict[ceph_server]:
            metric_name = METRIC_PREFIX + key
            out = out + '{}{{ceph_server="{}"}} {}\n'.format(
                metric_name, ceph_server, ceph_servers_dict[ceph_server][key]
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

    ceph_servers_dict = get_ceph_servers_dict()
    collect_values(ceph_servers_dict)
    dump_values(ceph_servers_dict)


if __name__ == "__main__":
    main()
