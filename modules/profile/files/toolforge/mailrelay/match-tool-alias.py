#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""
New Exim versions operate on so-called "taints" where untrusted data,
such as received email addresses cannot be used in unsafe contexts,
such as file paths, directly. This script is a workaround for that. We
want to support dynamic .forward.<foo> files, but the <foo> part there
is tainted by Exim. So this script takes that untrusted data, does some
basic checks and then returns it to Exim, as data from this script is
not tainted.
"""

import argparse
import pathlib

PREFIX = ".forward."


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=pathlib.Path)
    parser.add_argument("name", type=str)
    args = parser.parse_args()

    path = args.directory / f"{PREFIX}{args.name}"
    if path.exists() and path.is_file():
        print(str(path), end="")


if __name__ == "__main__":
    main()
