#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0


import mwopenstackclients

clients = mwopenstackclients.clients()

nova = clients.novaclient()
glance = clients.glanceclient()
images = glance.images.list()
imagedict = {f.id: f for f in images}
beforeimagedict = imagedict.copy()

if False:
    projects = clients.allprojects()
    for project in projects:
        glance_per_project = clients.glanceclient(project.id)
        project_images = glance_per_project.images.list()
        for project_image in project_images:
            if project_image.id not in imagedict:
                imagedict[project_image.id] = project_image

for id, image in imagedict.items():
    image.usage = 0

instances = clients.allinstances(allregions=True)
i = 0
for instance in instances:
    if instance.image["id"] not in imagedict:
        print(" -- unknown image %s" % instance.image["id"])
    else:
        imagedict[instance.image["id"]].usage += 1

sorted = {k: v for k, v in sorted(imagedict.items(), key=lambda item: item[1].usage)}

for id, image in sorted.items():
    print("%s: %s, %s" % (id, image.name, image.usage))
