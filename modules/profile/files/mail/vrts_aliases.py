#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Script to dump VRTS aliases, alerting if the list is already a gsuite email"""

import logging
import smtplib

from argparse import ArgumentParser
from configparser import ConfigParser
from pathlib import Path

import pymysql
import dbm
import subprocess

LOG = logging.getLogger(__file__)


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("-c", "--config", default=Path("/etc/exim4/vrts.conf"))
    parser.add_argument("-v", "--verbose", action="count")
    return parser.parse_args()


def get_log_level(args_level):
    """Configure logging"""
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


def verify_email(email, smtp_server):
    """Ensure email is a gsuite email address at smtp_server"""
    LOG.debug("Test: %s", email)
    smtp = smtplib.SMTP()
    smtp.connect(smtp_server)
    status, _ = smtp.helo()
    if status != 250:
        smtp.quit()
        raise ConnectionError("Failed helo status: {status}")
    smtp.mail("")
    status, _ = smtp.rcpt(email)
    smtp.quit()
    if status == 250:
        LOG.debug("Valid (%d): %s", status, email)
        return True
    LOG.debug("Invalid (%d): %s", status, email)
    return False


def main():
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    available, no_auth, gsuite = [], [], []
    valid_domains = []
    return_code = 0
    aliases = set()
    query = "SELECT value0, create_time, change_time FROM system_address"
    # List of emails handled by gsuite or postfix that cannot be removed from VRTS, see T284145
    known_invalid_addresses = [
        # gsuite
        "board@wikimedia.org",
        "business@wikimedia.org",
        "donation@wikimedia.org",
        "donations@wikimedia.org",
        "glam@wikimedia.org",
        "improve@wikimedia.org",
        "legal-en@wikimedia.org",
        "legal-tm-vio@wikimedia.org",
        "mobile-android-wikipedia@wikimedia.org",
        "mobile-ios-wikipedia@wikimedia.org",
        "postmaster@wikimedia.org",
        "postmaster@wikipedia.org",
        "press@wikimedia.org",
        "privacy@wikimedia.org",
        "security@wikimedia.org",
        "ux@wikimedia.org",
        "wikimania@wikimedia.org",
        "wm-cz@wikimedia.org",
        # postfix
        "donations@wikipedia.org",
        "donation@wikipedia.org",
        "jobs@wikipedia.org",
        "noc@wikimedia.org",
        "otrs@wikimedia.org",
        "privacy@wikidata.org",
        "security@wikipedia.org",
        "webmaster@wikimedia.org",
        "webmaster@wikipedia.org",
    ]

    config = ConfigParser()
    config.read(args.config)
    if "aliases_folder" not in config["DEFAULT"]:
        LOG.error("Config must contain DEFAULT[aliases_folder]")
        return 1
    if "aliases_format" not in config["DEFAULT"]:
        LOG.error("Config must contain DEFAULT[aliases_format] of 'exim' or 'postfix'")
        return 1
    if config["DEFAULT"]["aliases_format"] not in ["exim", "postfix"]:
        LOG.error("Config DEFAULT[aliases_format] must be 'exim' or 'postfix'")
        return 1
    if config["DEFAULT"]["aliases_format"] == "postfix":
        if "next_hop" not in config["DEFAULT"]:
            LOG.error("Must provide next_hop in DEFAULT config for postfix")
            return 1
        else:
            next_hop = config["DEFAULT"]["next_hop"]

    if config["DEFAULT"]["aliases_format"] == "exim":
        for f in Path(config["DEFAULT"]["aliases_folder"]).iterdir():
            if not f.is_file:
                continue
            domain = f.name
            # filter comments empty lines
            lines = filter(
                lambda line: line and line[0] != "#", f.read_text().splitlines()
            )
            # build email address from userpart and domain
            aliases.update({f"{line.split(':')[0]}@{domain}" for line in lines})
    elif config["DEFAULT"]["aliases_format"] == "postfix":
        for f in Path(config["DEFAULT"]["aliases_folder"]).glob("*.db"):
            # strip the .db extension to make dbm.open happy
            db_path = str(f.with_suffix(""))
            with dbm.open(db_path, "r") as db:
                for key in db.keys():
                    # postfix keys are NUL terminated, so we need to strip
                    aliases.add(key.decode(encoding="UTF-8").rstrip("\x00"))
    with Path(config["DEFAULT"]["valid_domains"]).open() as config_fh:
        valid_domains = [
            line.strip()
            for line in config_fh.readlines()
            if line.strip() and not line.startswith("#")
        ]
    LOG.debug("valid domains: %s", ", ".join(valid_domains))

    try:
        conn = pymysql.connect(
            host=config["DB"]["host"],
            user=config["DB"]["user"],
            password=config["DB"]["pass"],
            database=config["DB"]["name"],
        )
        with conn.cursor() as cur:
            cur.execute(query)
            for row in cur.fetchall():
                if row[0] in known_invalid_addresses:
                    # Skip emails handled by gsuite that cannot be removed from VRTS, see T284145
                    continue
                if row[0].split("@")[1] not in valid_domains:
                    LOG.warning("we don't handle email for %s", row[0])
                    no_auth.append(row)
                    continue
                if row[0] in aliases:
                    # Skip emails managed in aliases files
                    LOG.error("email is handled by postfix alias: %s", row[0])
                    continue
                if verify_email(row[0], config["DEFAULT"]["smtp_server"]):
                    LOG.error("email is handled by gsuite: %s", row[0])
                    return_code = 1
                    gsuite.append(row)
                else:
                    if row[0] not in available:
                        available.append(row[0])
    except (
        pymysql.MySQLError,
        smtplib.SMTPServerDisconnected,
        smtplib.SMTPConnectError,
        ConnectionError,
    ) as error:
        LOG.error(error)
        return 1
    with Path(config["DEFAULT"]["aliases_file"]).open("w") as aliases_fh:
        if config["DEFAULT"]["aliases_format"] == "exim":
            aliases_fh.writelines([f"{address}: {address}\n" for address in available])
        elif config["DEFAULT"]["aliases_format"] == "postfix":
            aliases_fh.writelines([f"{address}\t{next_hop}\n" for address in available])
    if config["DEFAULT"]["aliases_format"] == "postfix":
        subprocess.run(["postmap", Path(config["DEFAULT"]["aliases_file"])])
    return return_code


if __name__ == "__main__":
    raise SystemExit(main())
