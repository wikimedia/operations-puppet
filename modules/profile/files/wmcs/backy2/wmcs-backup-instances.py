#!/usr/bin/python3

import logging
import yaml

import mwopenstackclients3
import rbd2backy2

with open("/etc/wmcs_backup_instances.yaml") as f:
    config = yaml.safe_load(f)

openstackclients = mwopenstackclients3.Clients(envfile="/etc/novaobserver.yaml")

for project in config["projects"]:
    servers = openstackclients.allinstances(projectid=project)
    ceph_servers = rbd2backy2.ceph_vms(config["ceph_pool"])

    not_in_ceph = []
    for server in servers:
        if server.id in ceph_servers:
            logging.info("Backing up %s:%s" % (project, server.name))
            rbd2backy2.backup_vm(config["ceph_pool"], server.id)
        else:
            not_in_ceph.append(server)

    if not_in_ceph:
        logging.info("In project %s the following servers are not in ceph:")
        for server in not_in_ceph:
            logging.warning(" - %s (%s)" % (server.name, server.id))
