#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import sys
from typing import Optional

import mwopenstackclients


def find_server_id(hostname: str, project: str, nova) -> Optional[str]:
    """Find server ID by hostname and project."""

    servers = nova.servers.list(search_opts={"all_tenants": True, "name": hostname})

    for server in servers:
        if server.tenant_id != project:
            continue

        if server.name == hostname:
            return server.id

    return None


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Find OpenStack server ID by FQDN."
        " Will ask Nova in the current region and default domain."
    )
    parser.add_argument("fqdn", help="Server FQDN to search for.")

    args = parser.parse_args()

    try:
        hostname, project, _ = args.fqdn.split(".", 2)
    except ValueError:
        print(
            f"Unable to parse hostname and project from '{args.fqdn}'", file=sys.stderr
        )
        return 1

    clients = mwopenstackclients.clients(oscloud="novaobserver")
    nova = clients.novaclient()

    id = find_server_id(hostname, project, nova)

    if not id:
        print(f"Server with FQDN '{args.fqdn}' not found", file=sys.stderr)
        return 1

    print(id)
    return 0


if __name__ == "__main__":
    sys.exit(main())
