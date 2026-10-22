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

from ldap3 import ALL, Connection, Server
from ldap3.utils.conv import escape_filter_chars


def parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "input",
        help="JSON file containing a mapping of shell_name to username",
    )
    parser.add_argument(
        "--ldap-server",
        required=True,
        help="LDAP server URL, in the format ldap://hostname or ldaps://hostname",
    )
    parser.add_argument(
        "--ldap-base",
        required=True,
        help="LDAP base DN for searches",
        default="ou=people,dc=wikimedia,dc=org",
    )
    return parser.parse_args()


def get_ldap_cn_from_uid(uid, server, base):
    """Get the LDAP CN for a given UID."""
    server = Server(server, get_info=ALL)
    conn = Connection(server, auto_bind=True)
    search_filter = f"(uid={escape_filter_chars(uid)})"
    conn.search(search_base=base, search_filter=search_filter, attributes=["cn"])
    if not conn.entries:
        raise ValueError(f"User with UID '{uid}' not found in LDAP.")
    all_cns = []
    for entry in conn.entries:
        for cn in entry.cn.values:
            all_cns.append(str(cn))
    return all_cns


def main():
    """Generate a requestctl token for each shell_name => username pair."""
    args = parse_args()
    if os.geteuid() != 0:
        print("This script must be run as root.", file=sys.stderr)
        return 1
    all_users = json.loads(pathlib.Path(args.input).read_text(encoding="utf-8"))

    failures = 0
    for shell_name in all_users:
        is_failed = True
        output = f"/home/{shell_name}/.requestctl"
        for username in get_ldap_cn_from_uid(shell_name, args.ldap_server, args.ldap_base):
            # TODO: find out why some people have a lowercase username in HP.
            # This is just a nasty workaround.
            for u in [username, username.lower()]:
                try:
                    subprocess.run(
                        ["requestctl", "get-api-token", "-o", output, u],
                        check=True,
                    )
                    is_failed = False
                except subprocess.CalledProcessError:
                    continue
                if not is_failed:
                    break

        if is_failed:
            print(f"Failed to generate token for '{shell_name}'", file=sys.stderr)
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
