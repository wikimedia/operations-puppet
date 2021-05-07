#!/usr/bin/env python3
"""
Check our exclude_backups list is in sync with list config
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

import json
from pathlib import Path
import subprocess
import sys
from typing import List


def get_all_lists() -> List[str]:
    """all list names, in lowercase form"""
    return subprocess.check_output(
        ["/usr/lib/mailman/bin/list_lists", "-b"], text=True
    ).splitlines()


def is_archiving_disabled(listname) -> bool:
    # config might not be valid utf-8??
    config = subprocess.check_output(
        ["/usr/lib/mailman/bin/config_list", "-o", "-", listname]
    )
    # Either archive = 0 or archive = True
    return b"archive = 0" in config


def main() -> int:
    exclude_backups = set(json.loads(Path('/etc/exclude_backups_list.json').read_text()))
    archiving_disabled = set()
    all_lists = get_all_lists()
    for listname in all_lists:
        if is_archiving_disabled(listname):
            archiving_disabled.add(listname)
    # Some lists are no longer in MM2, so ignore them
    exclude_backups.intersection_update(set(all_lists))
    if exclude_backups != archiving_disabled:
        print("exclude_backups does not match lists with archiving disabled")
        exclude_extra = exclude_backups.difference(archiving_disabled)
        if exclude_extra:
            print("The following are in exclude_backups but don't have archiving disabled:\n")
            print("\n".join(exclude_extra))
            print("\n")
        exclude_missing = archiving_disabled.difference(exclude_backups)
        if exclude_missing:
            print("The following have archiving disabled but aren't in exclude_backups\n")
            print("\n".join(exclude_missing))
            print("\n")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
