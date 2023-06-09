#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Detect files that are not managed by Puppet

This script determines which files in the given directory are not
managed by Puppet. It is intended to be used to detect stale unmanaged
files when converting directories to purge mode. The script only
interacts with the local system, for a full picture you should run it
on all affected hosts via Cumin.

Usage example:
  $ sudo cumin "C:nftables" "locate-unmanaged /etc/nftables/"
"""
import argparse
from pathlib import Path
from sys import exit

import yaml


def report_constructor(loader, node):
    return loader.construct_mapping(node)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument(
        "--report",
        type=Path,
        default=Path("/var/lib/puppet/state/last_run_report.yaml"),
        help="Puppet report to work on",
    )
    args = parser.parse_args()

    yaml.add_constructor(
        "!ruby/object:Puppet::Transaction::Report",
        report_constructor,
        Loader=yaml.SafeLoader,
    )

    report = yaml.safe_load(args.report.read_text())

    all_managed_paths = [
        Path(resource.get("path", resource["title"]))
        for resource in report["resource_statuses"].values()
        if resource["resource_type"] == "File"
    ]

    for file in args.directory.glob("**/*"):
        if file in all_managed_paths:
            continue
        print(str(file))

    return 0


if __name__ == "__main__":
    exit(main())
