#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
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
import datetime
import importlib.machinery
import pickle
import shutil
import socket
import subprocess
import sys
import tempfile
import textwrap
import time
import traceback
import types

from pathlib import Path

import pymysql
import wmflib.config

from mailmanclient import Client

DOMAIN = "lists.wikimedia.org"


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


def get_client() -> Client:
    cfg = wmflib.config.load_ini_config("/etc/mailman3/mailman.cfg")
    return Client(
        "http://localhost:8001/3.1",
        cfg["webservice"]["admin_user"],
        cfg["webservice"]["admin_pass"],
    )


def get_webdb() -> pymysql.Connection:
    loader = importlib.machinery.SourceFileLoader(
        "mailman_web", "/etc/mailman3/mailman-web.py"
    )
    mod = types.ModuleType(loader.name)
    loader.exec_module(mod)
    cfg = mod.DATABASES["default"]
    return pymysql.connect(
        host=cfg["HOST"],
        user=cfg["USER"],
        password=cfg["PASSWORD"],
        database=cfg["NAME"],
        charset=cfg["OPTIONS"]["charset"],
    )


def fix_info(listname: str):
    """
    Try to import the longer info into Mailman3
    """
    config_pck = Path(f"/var/lib/mailman/lists/{listname}/config.pck")
    # https://gitlab.com/mailman/mailman/-/blob/732e97a3da9b6b3b27d152ea3458794f2c68f724/src/mailman/commands/cli_import.py#L76
    try:
        cfg = pickle.loads(config_pck.read_bytes(), encoding="utf-8", errors="ignore")
    except:  # noqa
        traceback.print_exc()
        # Not worth failing the whole import over
        print("Unable to open config.pck, can't manually set description")
        return
    if not cfg["info"]:
        print("Couldn't get info from Mailman2 config, not manually copying.")
        return
    client = get_client()
    mlist = client.get_list(f"{listname}@{DOMAIN}")
    mlist.settings["info"] = cfg["info"]
    mlist.settings.save()
    print("Manually copied over list description")


def fix_templates(listname: str):
    """
    Scan for templates on disk, import them into postorius,
    update mailman3 to get them from postorius, then
    delete them off disk.
    """
    templ_dir = Path(f"/var/lib/mailman3/templates/lists/{listname}.{DOMAIN}")
    if not templ_dir.is_dir():
        return
    lang_dirs = list(templ_dir.iterdir())
    if not lang_dirs:
        return
    lang_dir = lang_dirs[0]
    # Postorius only allows setting templates for one language
    if len(lang_dirs) > 1:
        skipped = ", ".join(lang.name for lang in lang_dirs[1:])
        print(
            f"WARNING: Only templates for {lang_dir.name} will be imported, skipping: {skipped}."
        )
        print("WARNING: Please delete the skipped templates after import")
    rows = []
    for template in lang_dir.glob("*.txt"):
        print(f"Importing {template.name}")
        rows.append(
            (
                # name
                template.name[:-4],  # Strip .txt suffix
                # data
                template.read_text(),
                # language
                "",
                # created_at
                datetime.datetime.utcnow(),
                # modified_at
                datetime.datetime.utcnow(),
                # context
                "list",
                # identifier
                f"{listname}.{DOMAIN}",
            )
        )
    if not rows:
        # No templates?
        return
    connection = get_webdb()
    with connection:
        with connection.cursor() as cursor:
            sql = "INSERT INTO postorius_emailtemplate (name, data, language, created_at, modified_at, context, identifier) VALUES (%s, %s, %s, %s, %s, %s, %s)"  # noqa
            cursor.executemany(sql, rows)
        connection.commit()
        print(f"Inserted {len(rows)} templates into `postorius_emailtemplate`.")
    # Use REST API to update mailman3 to point to postorius
    client = get_client()
    mlist = client.get_list(f"{listname}@{DOMAIN}")
    for row in rows:
        mlist.set_template(
            template_name=row[0],
            uri=f"https://{DOMAIN}/postorius/api/templates/list/{listname}.{DOMAIN}/{row[0]}",
            # For some reason mailman3 itself has username as NULL and password as empty string
            username=None,
            password="",
        )
    print("Updated mailman3.template table to point to postorius")
    shutil.rmtree(lang_dir)
    print(f"Deleted {lang_dir}")
    if not list(templ_dir.iterdir()):
        # Directory is empty, get rid of it too
        shutil.rmtree(templ_dir)
        print(f"Deleted {templ_dir}")


def check_call(args):
    """Wrapper to print the command being run"""
    print("$ " + " ".join(args))
    subprocess.check_call(args)


def main() -> int:
    args = parse_args()
    listname = args.listname
    listaddr = f"{listname}@{DOMAIN}"
    if Path(f"/var/lib/mailman3/lists/{listname}.{DOMAIN}").exists():
        print("Already done")
        return 0
    # FIXME don't do this
    if listname in Path("/home/ladsgroup/disabled_wikis").read_text().splitlines():
        print("Disabled")
        return 0
    print(f"Migrating {listname} to Mailman3")
    shutil.copyfile(
        f"/var/lib/mailman/lists/{listname}/config.pck",
        f"/var/lib/mailman/lists/{listname}/config.pck.backup"
    )
    send_email(
        to=f"{listname}-owner@{DOMAIN}",
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
    fix_info(listname)
    fix_templates(listname)
    check_call(["/usr/local/sbin/pipermail_redirects", listname])
    check_call(["/usr/local/sbin/disable_list", listname])
    send_email(
        to=f"{listname}-owner@{DOMAIN}",
        subject=f"{listname} mailing list migration complete",
        body=textwrap.dedent(
            f"""\
        Dear list administrator,

        Your mailing list, {listname}, has been migrated to Mailman3. You can
        access it at <https://{DOMAIN}/postorius/lists/{listname}.lists.wikimedia.org/>.

        Please create an account at <https://{DOMAIN}/accounts/signup/>.

        Finally, review <https://meta.wikimedia.org/wiki/Mailing_lists/Mailman3_migration>, which
        has some items to check.

        Happy emailing!
        """
        ),
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
