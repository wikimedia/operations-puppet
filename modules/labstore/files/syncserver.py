#!/usr/bin/python3
#
# Copyright (c) 2019 Wikimedia Foundation, Inc.
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
#
#  THIS FILE IS MANAGED BY PUPPET
#

import argparse
import logging
import netifaces
import subprocess
import sys
import time


class Rsyncer:
    """ The primary operator building and running rsync commands """

    def __init__(self, path, dest, bwlimit):
        self.path = path
        self.dest = dest
        self.bwlimit = bwlimit

    def sync(self):
        command = [
            "/usr/bin/rsync",
            "-a",
            "-e",
            "/usr/bin/ssh -i /root/.ssh/id_labstore",
            "--delete-after",
            "--contimeout=600",
            "--timeout=600",
            "--bwlimit={}".format(self.bwlimit),
            self.path,
            "{}:{}".format(self.dest, self.path),
        ]
        return subprocess.run(
            command, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )


def parse_args():
    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        "--sync-path", default="/exp/", help="Dir to sync between peer servers"
    )

    argparser.add_argument("--partner-host", help="FQDN of remote host")

    argparser.add_argument(
        "--bwlimit",
        help="Limit on bandwitdth for rsync in KBps",
        type=int,
        default=40000,
    )

    argparser.add_argument(
        "--config-path",
        default="/etc/nfs-mounts.yaml",
        help="Path to YAML file containing config of which exports to maintain",
    )

    argparser.add_argument(
        "--interval",
        type=int,
        default=0,
        help="Set interval to rerun at.  Default is 0 which means run once.",
    )

    argparser.add_argument(
        "--cluster-ip", help="The floating ip address of the cluster"
    )

    argparser.add_argument(
        "--debug", help="Turn on debug logging", action="store_true"
    )

    return argparser.parse_args()


def is_active_nfs(cluster_ip):
    """
    Return true if current host is the active NFS host

    It looks for an interface attached to the current host that has an IP
    that is the NFS cluster service IP.
    """
    for iface in netifaces.interfaces():
        ifaddress = netifaces.ifaddresses(iface)
        if netifaces.AF_INET not in ifaddress:
            continue
        if any(
            [ip["addr"] == cluster_ip for ip in ifaddress[netifaces.AF_INET]]
        ):
            return True
    return False


def main():
    args = parse_args()
    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(message)s",
        level=logging.DEBUG if args.debug else logging.INFO,
    )

    rsyncer = Rsyncer(args.sync_path, args.partner_host, args.bwlimit)

    if not args.interval and is_active_nfs(args.cluster_ip):
        logging.info("starting a sync...")
        result = rsyncer.sync()
        logging.info(result.stderr.decode("utf-8"))
        logging.info(result.stdout.decode("utf-8"))
        return result.returncode

    while True:
        time.sleep(args.interval)
        if is_active_nfs(args.cluster_ip):
            logging.info("starting a sync...")
            result = rsyncer.sync()
            if result.returncode != 0:
                logging.error(result.stderr.decode("utf-8"))
                logging.error(result.stdout.decode("utf-8"))
                return result.returncode


if __name__ == "__main__":
    sys.exit(main())
