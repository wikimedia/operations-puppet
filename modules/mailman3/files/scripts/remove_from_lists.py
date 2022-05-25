#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Remove an address from mailing lists
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

from mailmanclient import Client
import wmflib.config


def parse_args():
    parser = argparse.ArgumentParser(description="Remove an email address from mailing lists")
    parser.add_argument("email", help="Email address to remove")
    parser.add_argument("--only-private", action="store_true",
                        help="Only remove from private mailing lists")
    parser.add_argument("--dry-run", action="store_true",
                        help="Don't actually remove the address")
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
    email = args.email
    if args.dry_run:
        print("Dry-run mode enabled")
    if args.only_private:
        print(f"Going to unsubscribe {email} from all private mailing lists")
    else:
        print(f"Going to unsubscribe {email} from all mailing lists")
    client = get_client()
    for mlist in client.get_lists():
        if args.only_private:
            # A private list either:
            # * requires subscribers to be approved by moderators
            # * has private archives
            if mlist.settings["subscription_policy"] not in ('moderate', 'confirm_then_moderate') \
                    and mlist.settings["archive_policy"] != "private":
                # Meets neither of those conditions, skip
                continue
        if mlist.is_member(email) or mlist.is_owner_or_mod(email):
            if args.dry_run:
                print(f"Would have unsubscribed from {mlist.fqdn_listname}")
            else:
                mlist.unsubscribe(email, pre_confirmed=True, pre_approved=True)
                print(f"Unsubscribed from {mlist.fqdn_listname}")


if __name__ == "__main__":
    main()
