#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Discard held messages after a certain amount of days (T109838)
Copyright (C) 2021 Kunal Mehta <legoktm@debian.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""

import argparse
import datetime

from mailmanclient import Client
import wmflib.config


def parse_args():
    parser = argparse.ArgumentParser(
        description="Discard held messages after a certain amount of days")
    parser.add_argument("days", type=int, help="How many days old the message must be")
    parser.add_argument("--dry-run", action="store_true", help="Do not actually discard messages")
    return parser.parse_args()


def get_client() -> Client:
    cfg = wmflib.config.load_ini_config("/etc/mailman3/mailman.cfg")
    return Client(
        "http://localhost:8001/3.1",
        cfg["webservice"]["admin_user"],
        cfg["webservice"]["admin_pass"]
    )


def main():
    args = parse_args()
    if args.dry_run:
        print("Dry-run mode enabled")
    cutoff = datetime.datetime.utcnow() - datetime.timedelta(days=args.days)
    client = get_client()
    for mlist in client.get_lists():
        for message in mlist.held:
            hold_date = datetime.datetime.fromisoformat(message.hold_date)
            if hold_date <= cutoff:
                if args.dry_run:
                    print(f"Would have discarded {message.message_id} "
                          f"from {message.sender} to {mlist.fqdn_listname}")
                else:
                    message.discard()
                    print(f"Discarded {message.message_id} "
                          f"from {message.sender} to {mlist.fqdn_listname}")


if __name__ == "__main__":
    main()
