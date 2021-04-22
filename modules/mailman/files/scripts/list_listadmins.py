#!/usr/bin/env python3
"""
Dumps a list of all list admins
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

import ast
import subprocess
from typing import List


def get_all_lists() -> List[str]:
    """all list names, in lowercase form"""
    return subprocess.check_output(
        ["/usr/lib/mailman/bin/list_lists", "-b"], text=True
    ).splitlines()


def main():
    admins = set()
    for listname in get_all_lists():
        # config might not be valid utf-8??
        config = subprocess.check_output(
            ["/usr/lib/mailman/bin/config_list", "-o", "-", listname]
        )
        checks = b"OBSOLETE" in config or (
            b"member_moderation_action = 2" in config
            and b"generic_nonmember_action = 2" in config
            and b"emergency = 1" in config
        )
        if checks:
            # Skip obsolete list
            continue
        for line in config.splitlines():
            if line.startswith(b"owner = "):
                owners = ast.literal_eval(line[8:].decode())
                admins.update(set(owners))
                break

    for admin in sorted(admins):
        print(admin)


if __name__ == "__main__":
    main()
