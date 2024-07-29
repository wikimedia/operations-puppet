#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import argparse
import sys

from typing import List

import bituldap as ldap


def main():
    parser = argparse.ArgumentParser(
                    prog="add-ldap-group",
                    description="Create new LDAP group"
    )

    parser.add_argument("name", help="Name of the group to create")
    parser.add_argument("--gid", action="store", default=0, type=int,
                        help="The group's gid (default: next available gid)")
    parser.add_argument("--members", action="store", nargs='+', default=None,
                        help="A comma separated list of group members to add to this group")
    parser.add_argument("--ignore-existing", action="store_true",
                        help="If the group exist, do not attempt to create, "
                             + "but do add any members given.")

    args = parser.parse_args()

    # Check if the group already exist.
    # Exist if required.
    group = ldap.get_group(args.name)
    if group and not args.ignore_existing:
        print(f'group {args.name} already exists, with {len(group.member)} members, '
              + 'use --ignore-existing to add members to existing group.')
        return 1

    # The group didn't exist, create it.
    if not group:
        success, group = ldap.new_group(args.name, args.gid)
    else:
        # Set true, to indicate successful "creation" of existing group.
        success = True

    members: List[str] = []
    if args.members and success:
        store = False
        # Add any missing members to the group.
        for member in args.members:
            member_dn = ldap.get_user(member).entry_dn
            if not member_dn:
                print(f"The user {member} seems not present in LDAP, skipping.")
            elif member_dn not in group.member:
                group.member += member_dn
                store = True  # Note that we need to call commit.

        # One or more members where added, commit to LDAP.
        if store:
            success = group.entry_commit_changes()

        # Failed to commit new members to LDAP.
        if not success:
            print(f"successfully created group {args.name}, "
                  + f"with gidNumber {group.gidNumber}, "
                  + "but failed to add members")
            return 1

    # Everything went well.
    if success:
        print(f"successfully created group {args.name}, "
              + f"with gidNumber {group.gidNumber} and {len(members)} members")
        return 0

    # Failed to create group
    print(f"error creating group: {args.name}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
