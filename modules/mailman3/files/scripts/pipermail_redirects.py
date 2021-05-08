#!/usr/bin/env python3
"""
Generate pipermail redirects
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
import base64
import hashlib
import re
import shutil
import subprocess
import tempfile

import requests
import sys

from pathlib import Path
from typing import Optional
from urllib.parse import parse_qs, urlparse

DOMAIN = "lists.wikimedia.org"
RE_LINK = re.compile(r"<LINK REL=\"made\"\s+HREF=\"(.*?)\">")
RE_WHITESPACE = re.compile(r"\s")


session = requests.session()


def parse_args():
    parser = argparse.ArgumentParser(description="Generate pipermail redirects")
    parser.add_argument("listname", help="List name")
    parser.add_argument("--rebuild-only", action="store_true", help="Only rebuild redirects.dbm")
    parser.add_argument("--no-rebuild", action="store_true", help="Don't rebuild redirects.dbm")
    return parser.parse_args()


def extract_in_reply_to(path: Path) -> Optional[str]:
    text = path.read_text()
    search = RE_LINK.search(text)
    if not search:
        print(f"Could not extract In-Reply-To from {path}, skipping")
        return
    link = urlparse(search.group(1))
    query = parse_qs(link.query)
    if "In-Reply-To" not in query:
        print(f"Could not extract In-Reply-To from {path}, skipping")
        return
    in_reply_to = query["In-Reply-To"][0]
    # Clean < ... >
    if in_reply_to.startswith("<") and in_reply_to.endswith(">"):
        in_reply_to = in_reply_to[1:-1]
    # Remove all whitespace
    return RE_WHITESPACE.sub("", in_reply_to)


def calculate_hash(message_id: str) -> str:
    """https://wiki.list.org/DEV/Stable%20URLs"""
    return base64.b32encode(hashlib.sha1(message_id.encode()).digest()).decode()


def handle_email(listname: str, path: Path) -> Optional[str]:
    message_id = extract_in_reply_to(path)
    if message_id is None:
        return
    message_id_hash = calculate_hash(message_id)
    hk_part = f"{listname}@{DOMAIN}/message/{message_id_hash}/"
    req = session.get(f"https://lists.wikimedia.org/hyperkitty/list/{hk_part}")
    if req.status_code != 200:
        print(f"{path} does not appear to be archived in hyperkitty!")
        return
    first = str(path).replace("/var/lib/mailman/archives/public/", "")
    return f"{first} {hk_part}"


def rebuild_dbm():
    folder = Path("/var/lib/mailman3/redirects/")
    tmp = folder / "redirects.dbm.new"
    dbm = folder / "redirects.dbm"
    # Grab all the *.txt files to turn into one dbm
    with tempfile.NamedTemporaryFile() as f:
        for txt in folder.iterdir():
            if txt.name.endswith(".txt"):
                f.write(txt.read_bytes())
        f.seek(0)
        print("Regenerating redirects.dbm...")
        # Generate to a tmp file and then overwrite the real dbm file
        subprocess.run(["httxt2dbm", "-i", "-", "-o", str(tmp)], stdin=f)
        shutil.move(tmp, dbm)


def main() -> int:
    args = parse_args()
    if args.rebuild_only:
        rebuild_dbm()
        return 0
    listname = args.listname
    public = Path(f"/var/lib/mailman/archives/public/{listname}")
    if not public.exists():
        print(f"List {listname} has no public archives, skipping.")
        return 0
    if not Path(f"/var/lib/mailman3/lists/{listname}.{DOMAIN}").exists():
        print(f"List {listname} doesn't exist in Mailman3 yet.")
        return 1
    txt = Path(f"/var/lib/mailman3/redirects/{listname}.txt")
    if txt.exists():
        print(f"{txt} already exists, overwriting.")
        txt.unlink()
    with txt.open("a") as f:
        for month in sorted(public.iterdir()):
            if not month.name.startswith("20") or not month.is_dir():
                continue
            print(f"Going through {month.name}...")
            for email in sorted(month.iterdir()):
                if email.name.startswith("0") and email.name.endswith(".html"):
                    line = handle_email(listname, email)
                    if line is not None:
                        f.write(f"{line}\n")

    # Now rebuild the entire dbm
    if not args.no_rebuild:
        rebuild_dbm()

    return 0


if __name__ == "__main__":
    sys.exit(main())
