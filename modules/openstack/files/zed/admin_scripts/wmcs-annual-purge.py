#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

# Print wikitext for use in the annual purge page:
#  fqdn, id, ip, flavor -- grouped by project

import mwopenstackclients

clients = mwopenstackclients.clients(envfile="/etc/novaadmin.yaml")

allprojects = clients.allprojects()

for project in allprojects:
    print("\n=== %s ===\n" % project.id)

    servers = clients.allinstances(projectid=project.id)
    flavors = clients.novaclient(project=project.id).flavors.list()
    flavordict = {f.id: f.name for f in flavors}

    for server in servers:
        if server.flavor["id"] in flavordict:
            flavorname = flavordict[server.flavor["id"]]
        else:
            flavorname = "(unknown flavor)"
        print(
            "%s.%s.eqiad1.wikimedia.cloud %s %s %s\n"
            % (
                server.name,
                project.id,
                server.id,
                server.addresses["lan-flat-cloudinstances2b"][0]["addr"],
                flavorname,
            )
        )
