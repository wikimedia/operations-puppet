#!/usr/bin/python3
#
# Copyright 2017 Wikimedia Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import argparse
import subprocess

import mwopenstackclients

clients = mwopenstackclients.clients()


def purge_orphan_images(delete=False):
    rbd_output = subprocess.check_output(["rbd", "--pool", "eqiad1-compute", "ls", "-l"]).decode(
        "utf8"
    )
    ceph_vm_images = {}
    mystery_images = []
    # First line is column headers
    for imageline in rbd_output.splitlines()[1:]:
        imagename = imageline.split(" ")[0]
        if "_" in imagename:
            vm_name = imagename.split("_")[0]
            if vm_name not in ceph_vm_images:
                ceph_vm_images[vm_name] = [imagename]
            else:
                ceph_vm_images[vm_name].append(imagename)
        else:
            mystery_images.append(imagename)

    instances = clients.allinstances(allregions=True)
    # instancedict = {instance.id: instance for instance in instances}
    all_instance_ids = set([instance.id for instance in instances])
    all_image_ids = set(ceph_vm_images.keys())

    leaked_images = []
    for instanceid in all_image_ids - all_instance_ids:
        leaked_images.extend(ceph_vm_images[instanceid])
        print(instanceid + ":")
        for image in ceph_vm_images[instanceid]:
            print("        " + image)

    print("%s images without VMs" % len(leaked_images))


parser = argparse.ArgumentParser(description="Find (and, optionally, remove) leaked dns records.")
parser.add_argument(
    "--delete", dest="delete", help="Actually delete leaked images", action="store_true"
)
args = parser.parse_args()

purge_orphan_images(args.delete)
