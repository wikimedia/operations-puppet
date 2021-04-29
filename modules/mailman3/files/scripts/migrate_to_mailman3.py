#!/usr/bin/env python3
"""
Copyright (C) 2021 Amir Sarabadani <ladsgroup@gmail.com>
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
import socket
import subprocess
import sys
import tempfile
import textwrap
import time

from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description="Migrate a mailing list to Mailman3!")
    parser.add_argument("listname", help="Name of mailing list to migrate")
    return parser.parse_args()


def send_email(to: str, subject: str, body: str):
    with tempfile.NamedTemporaryFile() as f:
        f.write(body.encode())
        f.seek(0)
        subprocess.run(
            ["mail", "-s", subject, "-r", f"noreply@{socket.getfqdn()}", "--", to],
            stdin=f,
            check=True,
        )
    print(f"Sent email to {to}")


def check_call(args):
    """Wrapper to print the command being run"""
    print("$ " + " ".join(args))
    subprocess.check_call(args)


def main() -> int:
    args = parse_args()
    listname = args.listname
    listaddr = f"{listname}@lists.wikimedia.org"
    if Path(f"/var/lib/mailman3/lists/{listname}.lists.wikimedia.org").exists():
        print("Already done")
        return 0
    # FIXME don't do this
    if listname in Path("/home/ladsgroup/disabled_wikis").read_text():
        print("Disabled")
        return 0
    print(f"Migrating {listname} to Mailman3")
    send_email(
        to=f"{listname}-owner@lists.wikimedia.org",
        subject=f"{listname} mailing list is being migrated to Mailman3",
        body=textwrap.dedent(
            f"""\
        Dear list administrator,

        Your mailing list, {listname}, is being migrated to Mailman3. You will
        receive another email once the migration has finished.
        """
        ),
    )
    time.sleep(5)
    check_call(["mailman-wrapper", "create", listaddr])
    check_call(
        [
            "mailman-wrapper",
            "import21",
            listaddr,
            f"/var/lib/mailman/lists/{listname}/config.pck",
        ]
    )
    check_call(["mailman-web", "mailman_sync"])
    check_call(
        [
            "mailman-web",
            "hyperkitty_import",
            "-l",
            listaddr,
            f"/var/lib/mailman/archives/private/{listname}.mbox/{listname}.mbox",
        ]
    )
    check_call(["mailman-web", "update_index_one_list", listaddr])
    check_call(["/usr/local/sbin/disable_list", listname])
    send_email(
        to=f"{listname}-owner@lists.wikimedia.org",
        subject=f"{listname} mailing list migration complete",
        body=textwrap.dedent(
            f"""\
        Dear list administrator,

        Your mailing list, {listname}, has been migrated to Mailman3. You can
        access it at <https://lists.wikimedia.org/postorius/lists/{listname}.lists.wikimedia.org/>.

        Please create an account at <https://lists.wikimedia.org/accounts/signup/>.

        Finally, review <https://meta.wikimedia.org/wiki/Mailing_lists/Mailman3_migration>, which
        has some items to check.

        Happy emailing!
        """
        ),
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
