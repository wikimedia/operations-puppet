#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

# Print wikitext for use in the annual purge page:
#  fqdn, id, ip, flavor -- grouped by project

import json
import mwopenstackclients
import subprocess

clients = mwopenstackclients.clients(oscloud="novaadmin")

allprojects = clients.allprojects()
sortedprojects = sorted(allprojects, key=lambda d: d.name)

for project in sortedprojects:
    print(
        "\n=== [https://openstack-browser.toolforge.org/project/%s %s] ===\n"
        % (project.name, project.name)
    )

    if (
        project.name == "trove"
        or project.name == "tools"
        or project.name == "octavia"
        or project.name == "cloudvirt-canary"
        or project.name == "admin-monitoring"
    ):
        print("Many instances!")
        continue

    servers = clients.allinstances(projectid=project.id)
    flavors = clients.novaclient(project=project.id).flavors.list()
    flavordict = {f.id: f.name for f in flavors}

    for server in servers:
        if server.flavor["id"] in flavordict:
            flavorname = flavordict[server.flavor["id"]]
        else:
            flavorname = "(unknown flavor)"
        if "VLAN/legacy" in server.addresses:
            print(
                "%s.%s.eqiad1.wikimedia.cloud %s %s %s\n"
                % (
                    server.name,
                    project.name,
                    server.id,
                    server.addresses["VLAN/legacy"][0]["addr"],
                    flavorname,
                )
            )
        elif "VXLAN/IPv4-only" in server.addresses:
            print(
                "%s.%s.eqiad1.wikimedia.cloud %s %s %s\n"
                % (
                    server.name,
                    project.id,
                    server.id,
                    server.addresses["VXLAN/IPv4-only"][0]["addr"],
                    flavorname,
                )
            )
        elif "VXLAN/IPv6-only" in server.addresses:
            print(
                "%s.%s.eqiad1.wikimedia.cloud %s %s %s\n"
                % (
                    server.name,
                    project.id,
                    server.id,
                    server.addresses["VXLAN/IPv6-only"][0]["addr"],
                    flavorname,
                )
            )
        elif "VXLAN/IPv6-dualstack" in server.addresses:
            ipv4 = server.addresses["VXLAN/IPv6-dualstack"][0]["addr"]
            if len(server.addresses["VXLAN/IPv6-dualstack"]) > 1:
                ipv6 = server.addresses["VXLAN/IPv6-dualstack"][1]["addr"]
            else:
                ipv6 = ""

            print(
                "%s.%s.eqiad1.wikimedia.cloud %s %s %s %s\n"
                % (
                    server.name,
                    project.id,
                    server.id,
                    ipv4,
                    ipv6,
                    flavorname,
                )
            )
        else:
            print("Found server with unknown address type")
            print(server.addresses)
            exit(1)

    databaseservers = clients.troveclient(project.id).instances.list()
    for server in databaseservers:
        print("Database server: %s (%s)" % (server.name, server.datastore["type"]))

    try:
        object_buckets = json.loads(
            subprocess.check_output(
                [
                    "/usr/bin/radosgw-admin",
                    "--format",
                    "json",
                    "bucket",
                    "list",
                    "--uid",
                    "%s$%s" % (project.id, project.id),
                ],
                stderr=subprocess.DEVNULL,
            ).decode("utf8")
        )

        for bucket in object_buckets:
            print("\nObject storage bucket: %s" % bucket)

    except subprocess.CalledProcessError:
        # radosgw doesn't know about this project. No problem.
        pass
