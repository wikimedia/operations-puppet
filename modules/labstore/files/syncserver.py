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
import subprocess
import time


class Rsyncer:
    """ The primary operator building and running rsync commands """

    def init(self, path, dest, bwlimit):
        self.path = path
        self.dest = dest
        self.bwlimit = bwlimit

    def sync(self):
        command = [
            "/usr/bin/rsync",
            "-a",
            "--delete-after",
            "--contimeout=600",
            "--timeout=600",
            "--bwlimit={}".format(self.bwlimit),
            "{}:{}".format(self.dest, self.path),
        ]
        return subprocess.run(command)


def parse_args():
    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        "--sync-path", default="/exp/", help="Dir to sync between peer servers"
    )

    argparser.add_argument(
        "--primary-host", help="The ip address of the primary NFS server"
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
        "--debug", help="Turn on debug logging", action="store_true"
    )

    return argparser.parse_args()


def main():
    args = parse_args()
    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(message)s",
        level=logging.DEBUG if args.debug else logging.INFO,
    )

    # TODO: actually do something instead of just burning cycles
    while True:
        time.sleep(args.interval)


if __name__ == "__main__":
    main()
