#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0


import mwopenstackclients

clients = mwopenstackclients.clients()

nova = clients.novaclient()
flavors = nova.flavors.list()
flavordict = {f.id: f for f in flavors}


projects = clients.allprojects()
for project in projects:
    nova_per_project = clients.novaclient(project.id)
    project_flavors = nova_per_project.flavors.list()
    for project_flavor in project_flavors:
        if project_flavor.id not in flavordict:
            flavordict[project_flavor.id] = project_flavor

for id, flavor in flavordict.items():
    flavor.usage = 0

instances = clients.allinstances(allregions=True)
i = 0
for instance in instances:
    if instance.flavor["id"] not in flavordict:
        print("flavordict missing %s?" % instance.flavor["id"])
    else:
        flavordict[instance.flavor["id"]].usage += 1

sorted = {k: v for k, v in sorted(flavordict.items(), key=lambda item: item[1].usage)}

for id, flavor in sorted.items():
    print("%s: %s, %s" % (id, flavor, flavor.usage))
