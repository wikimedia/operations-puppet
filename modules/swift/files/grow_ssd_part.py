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


def part_umount(device, partnum):
    node = _devpart(device, partnum)
    mounted = subprocess.run(["/usr/bin/findmnt", node], capture_output=True)
    if mounted.returncode == 0:
        _run(["/usr/bin/umount", node])


def part_delete(device, partnum):
    _run(["/usr/sbin/sfdisk", "--delete", device, partnum])
    _run(["/usr/sbin/partprobe", device])


def part_grow(device, part, size_megabytes):
    node = _devpart(device, part)

    _run(
        "echo ',+{}M' | sfdisk {} -N {}".format(size_megabytes, device, part),
        shell=True,
    )
    _run(["/usr/sbin/partprobe", device])

    _run(["/usr/sbin/xfs_growfs", node])


def part_append(device, part):
    node = _devpart(device, part)

    _run("echo , | sfdisk --append {}".format(device), shell=True)
    _run(["/usr/sbin/partprobe", device])

    assert stat.S_ISBLK(os.stat(node).st_mode)

    _run(["/usr/sbin/mkfs.xfs", node])


def ptable_backup(device, outfile):
    with open(outfile, "w") as f:
        ptable = subprocess.check_output(["/usr/sbin/sfdisk", "--dump", device])
        f.write(ptable)


def grow(device, p1, p2, size_megabytes):
    ptable_json = subprocess.check_output(["/usr/sbin/sfdisk", "-J", device])
    ptable = json.loads(ptable_json)
    partitions = ptable["partitiontable"]["partitions"]

    node1 = _devpart(device, p1)
    node2 = _devpart(device, p2)

    part1 = None
    part2 = None

    for p in partitions:
        part = Partition(**p)
        if part.node == node1:
            part1 = part
        if part.node == node2:
            part2 = part

    assert (
        0
        < part2.start - (part1.start + part1.size)
        < ptable["partitiontable"]["sectorsize"]
    ), "Partitions {} and {} are not contiguous on {}".format(p1, p2, device)

    part_umount(device, p2)
    part_delete(device, p2)

    part_grow(device, p1, size_megabytes)

    part_append(device, p2)


def main():
    global DRY_RUN

    parser = argparse.ArgumentParser()

    parser.add_argument("--mb", type=str, help="How many megabytes to add to part1")
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

    DRY_RUN = not args.doit

    grow(args.dev, args.part1, args.part2, args.mb)


if __name__ == "__main__":
    main()
