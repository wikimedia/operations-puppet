#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) Giuseppe Lavagetto, Wikimedia Foundation 2026
"""Generate requestctl API tokens for a set of users.

Reads a JSON file mapping shell names to usernames and, for each pair, runs
``requestctl get-api-token -o /home/<shell_name>/.requestctl '<username>'``.
"""

import argparse
import json
import os
import pathlib
import subprocess
import sys


def parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "input",
        help="JSON file containing a mapping of shell_name to username",
    )
    return parser.parse_args()


def main():
    """Generate a requestctl token for each shell_name => username pair."""
    args = parse_args()
    if os.geteuid() != 0:
        print("This script must be run as root.", file=sys.stderr)
        return 1
    mapping = json.loads(pathlib.Path(args.input).read_text(encoding="utf-8"))

    failures = 0
    for shell_name, username in mapping.items():
        output = f"/home/{shell_name}/.requestctl"
        try:
            subprocess.run(
                ["requestctl", "get-api-token", "-o", output, username],
                check=True,
            )
        except subprocess.CalledProcessError as exc:
            print(
                f"Failed to generate token for '{username}' ({shell_name}): {exc}",
                file=sys.stderr,
            )
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
