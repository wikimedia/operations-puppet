#!/usr/bin/python3
# Dump fqdns for all VMs, sorted by project and hypervisor

import mwopenstackclients

clients = mwopenstackclients.clients(envfile="/etc/novaadmin.yaml")
hypervisors = clients.novaclient().services.list()
hvnames = sorted([hv.host for hv in hypervisors])

for hv in hvnames:
    print("\n== %s ==\n" % hv)
    servers = clients.novaclient().servers.list(search_opts={"all_tenants": True, "host": hv})
    projdict = {}
    for server in servers:
        if server.tenant_id not in projdict:
            projdict[server.tenant_id] = [server]
        else:
            projdict[server.tenant_id].append(server)

    for project in sorted(projdict):
        for server in projdict[project]:
            print("%s.%s.eqiad1.wikimedia.cloud (%s)" % (server.name, project, server.id))
