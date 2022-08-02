#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

# This script will allocate more space for Swift' SSD partition hosting
# container databases.  The use case is the need to have more space to move
# around big containers, see also https://phabricator.wikimedia.org/T314275.

import argparse
import json
import logging
import os
import stat
import string
import subprocess
from dataclasses import dataclass

log = logging.getLogger()
logging.basicConfig(level=logging.INFO)
DRY_RUN = True


@dataclass
class Partition:
    node: str
    start: int
    size: int
    type: str
    bootable: bool = False
    mountpoint: str = None
    label: str = None
    num: int = -1
    dev: str = None

    def __post_init__(self):
        mnt = subprocess.check_output(
            ["/usr/bin/findmnt", "--noheadings", "--output", "target", self.node]
        )
        self.mountpoint = mnt.decode("utf8").strip()
        self.label = "swift-{}".format(os.path.basename(self.mountpoint))


def _devpart(device, partnum):
    dev = device
    if dev[-1] in string.digits:
        dev += "p"

    return "{}{}".format(dev, partnum)


def _run(*args, **kwargs):
    if DRY_RUN:
        log.info("Will run %r %r", args, kwargs)
        return None

    log.info("Running %r %r", args, kwargs)
    return subprocess.check_output(*args, **kwargs)


def part_umount(part):
    mounted = subprocess.run(["/usr/bin/findmnt", part.node], capture_output=True)
    if mounted.returncode == 0:
        _run(["/usr/bin/umount", part.node])


def part_delete(part):
    _run(["/usr/sbin/sfdisk", "--delete", part.dev, part.num])
    _run(["/usr/sbin/partprobe", part.dev])


def part_grow(part, amount):
    _run(
        "echo ',+{}' | sfdisk --no-reread {} -N {}".format(amount, part.dev, part.num),
        shell=True,
    )
    _run(["/usr/sbin/partprobe", part.dev])
    _run(["/usr/sbin/xfs_growfs", part.mountpoint])


def part_append(part):
    _run("echo , | sfdisk --no-reread --append {}".format(part.dev), shell=True)
    _run(["/usr/sbin/partprobe", part.dev])

    assert stat.S_ISBLK(os.stat(part.node).st_mode)

    _run(["/usr/sbin/mkfs.xfs", "-L", part.label, part.node])


def ptable_backup(device, outfile):
    with open(outfile, "w") as f:
        ptable = subprocess.check_output(["/usr/sbin/sfdisk", "--dump", device])
        f.write(ptable)


def grow(device, p1, p2, amount):
    ptable_json = subprocess.check_output(["/usr/sbin/sfdisk", "-J", device])
    ptable = json.loads(ptable_json)
    partitions = ptable["partitiontable"]["partitions"]

    node1 = _devpart(device, p1)
    node2 = _devpart(device, p2)

    part1 = None
    part2 = None

    for p in partitions:
        if p["node"] == node1:
            part1 = Partition(**p)
            part1.num = p1
            part1.dev = device
        if p["node"] == node2:
            part2 = Partition(**p)
            part2.num = p2
            part2.dev = device

    # Might not be available/detected, be optimistic
    sectorsize = ptable["partitiontable"].get("sectorsize", 4096)

    assert (
        0 <= part2.start - (part1.start + part1.size) < sectorsize
    ), "Partitions {} and {} are not contiguous on {}".format(p1, p2, device)

    part_umount(part2)
    part_delete(part2)

    part_grow(part1, amount)

    part_append(part2)


def main():
    global DRY_RUN

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--amount", type=str, help="How many bytes to add to part1. Use G or M suffix."
    )
    parser.add_argument("--dev", type=str, help="Device to act on")
    parser.add_argument(
        "--part1", type=str, default="3", help="Partition number to grow"
    )
    parser.add_argument(
        "--part2",
        type=str,
        default="4",
        help="Partition number to delete and recreate, must be after part1",
    )
    parser.add_argument(
        "--doit", default=False, action="store_true", help="Actually do something"
    )
    args = parser.parse_args()

    if args.amount[-1] not in "MG":
        parser.error("Use M or G suffix for --amount")

    DRY_RUN = not args.doit

    grow(args.dev, args.part1, args.part2, args.amount)


if __name__ == "__main__":
    main()
