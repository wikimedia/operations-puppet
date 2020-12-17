#!/usr/bin/python3

import logging

import mwopenstackclients
import rbd2backy2
import yaml

with open("/etc/wmcs_backup_images.yaml") as f:
    config = yaml.safe_load(f)

clients = mwopenstackclients.Clients(envfile="/etc/novaadmin.yaml")
glance = clients.glanceclient()
images = glance.images.list()

for image in images:
    logging.info("Backing up %s (%s)" % (image.id, image.name))
    rbd2backy2.backup_volume(
        config["ceph_pool"], image.id, config["live_for_days"]
    )
