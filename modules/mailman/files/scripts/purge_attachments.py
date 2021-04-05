#!/usr/bin/env python3
"""
Purge attachments from lists with archiving disabled
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

This script works around a limitation in mailman that attachments
(including text/html) parts are left around indefinitely even though
list archiving is disabled for digests. We now cleanup these attachments
after a month.

See https://bugs.launchpad.net/mailman/+bug/266317#5
"""

import argparse
from datetime import datetime
from pathlib import Path
import shutil
import subprocess
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


def parse_args():
    parser = argparse.ArgumentParser(
        description="Purge attachments from lists without archiving enabled"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Don't actually delete anything"
    )
    return parser.parse_args()


def main():
    args = parse_args()
    if args.dry_run:
        print("Dry-run mode enabled")
    for listname in get_all_lists():
        if not is_archiving_disabled(listname):
            continue
        path = Path(f"/var/lib/mailman/archives/private/{listname}/attachments")
        if not path.exists():
            continue
        for datedir in sorted(path.iterdir()):
            if not datedir.is_dir():
                continue
            try:
                date = datetime.strptime(str(datedir.name), "%Y%m%d")
            except ValueError:
                print(f"Invalid date wtf: {datedir}")
                continue
            if (datetime.utcnow() - date).days > 31:
                if args.dry_run:
                    print(f"Would have deleted {datedir}")
                else:
                    shutil.rmtree(str(datedir))
                    print(f"Deleted {datedir}")


if __name__ == "__main__":
    main()
