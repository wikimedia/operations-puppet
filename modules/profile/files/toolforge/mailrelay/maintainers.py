#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# THIS FILE IS MAINTAINED BY PUPPET
"""
This script is called in the Exim configuration to look up which email
addresses to forward mail to an individual tool if there is no .forward
file. The syntax is simple:

 $ /usr/local/sbin/maintainers tools.admin

It must return either a comma-separated list of mail addresses, or a
pseudo-command like :blackhole: or :fail: if no addresses are present.

For more details, see:
 * https://www.exim.org/exim-html-current/doc/html/spec_html/ch-the_redirect_router.html
 * https://wikitech.wikimedia.org/wiki/Help:Toolforge/Email
"""

# FIXME: For nested service groups, this returns only the addresses of
# users who are direct members of the service group queried, but not
# of those who are members of the related service groups.  This should
# be replaced by a proper recursive query with protections against
# circular loops, etc.

import argparse
import logging
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

import ldap3
import yaml
from systemd.journal import JournalHandler

LOGGER = logging.getLogger("toolforge-exim-maintainers")


def get_ldap_conn(ldap_config: Dict[str, Any]) -> ldap3.Connection:
    """
    Return a ldap connection

    Return value can be used as a context manager
    """
    servers = ldap3.ServerPool(
        [ldap3.Server(s, connect_timeout=1) for s in ldap_config["servers"]],
        ldap3.ROUND_ROBIN,
        active=True,
        exhaust=True,
    )

    return ldap3.Connection(
        servers,
        read_only=True,
        user=ldap_config["user"],
        auto_bind=True,
        password=ldap_config["password"],
        raise_exceptions=True,
        receive_timeout=60,
    )


def get_maintainer_emails(group: str, conn: ldap3.Connection) -> Optional[List[str]]:
    result = conn.extend.standard.paged_search(
        "ou=people,dc=wikimedia,dc=org",
        f"(&(objectclass=person)(memberOf=cn={group},ou=servicegroups,dc=wikimedia,dc=org))",
        attributes=["mail"],
        time_limit=5,
        paged_size=256,
        generator=True,
    )

    attributes = [
        user["attributes"]["mail"]
        for user in result
        if "mail" in user.get("attributes", {})
    ]

    # No maintainers found in practice means that the tool does not exist, since
    # Striker does not allow making a maintainer-less tool.
    if len(attributes) == 0:
        return None

    # Flatten the list of mail attribute values per user, and filter out empty mails.
    return [
        item
        for maintainer in attributes
        for item in maintainer
        if item != ""
    ]


def get_tool() -> Optional[str]:
    parser = argparse.ArgumentParser()
    parser.add_argument("tool")
    tool = parser.parse_args().tool
    # This is intentionally much wider than the actual name pattern.
    # It's mostly here to protect against any LDAP attacks.
    if not re.match(r"^[a-z0-9\-\.]{1,64}$", tool):
        return None
    return tool


def main():
    tool = get_tool()
    if not tool:
        print(":fail: The given tool name is invalid.")
        return

    with Path("/etc/ldap.yaml").open("r") as f:
        config = yaml.safe_load(f)
    with get_ldap_conn(config) as conn:
        emails = get_maintainer_emails(tool, conn)

    if emails is None:
        print(":fail: This tool does not exist.")
        return
    if len(emails) == 0:
        # In theory all maintainers should have an email address set. However, in
        # practice some maintainers have no email addresses in LDAP, and we
        # don't want mails to those tools to get stuck in the queue immediately,
        # so we blackhole them.
        print(":blackhole:")
        return

    # Success! We have some emails that we can use.
    print(", ".join(sorted(emails)))


if __name__ == "__main__":
    # Send logs to journal, so we can only print the control data that exim will use.
    LOGGER.addHandler(JournalHandler(SYSLOG_IDENTIFIER="toolforge-exim-maintainers"))
    LOGGER.setLevel(logging.INFO)

    try:
        main()
    except Exception:
        LOGGER.exception("Failed to load maintainers from LDAP")
        # Tell Exim to defer the mail.
        print(":defer: Failed to look up maintainer data from LDAP.")
