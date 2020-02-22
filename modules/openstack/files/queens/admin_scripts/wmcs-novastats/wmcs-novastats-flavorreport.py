#!/usr/bin/python

import mwopenstackclients

clients = mwopenstackclients.clients()

nova = clients.novaclient()
flavors = nova.flavors.list()

flavordict = {f.id: f.disk for f in flavors}

# extras that our query can't pick up
flavordict['7'] = '80'
flavordict['101'] = '40'
flavordict['bb5bf060-cdbb-4448-b436-a015ae2d4aaf'] = '160'
flavordict['8af1f1cc-d95f-4380-bf10-bcfa0321b10f'] = '60'
flavordict['2d59cc0d-538c-4bbd-b975-8e696a4f7207'] = '80'
flavordict['deea3460-069e-44c7-98ca-ae30bb0de772'] = '80'
flavordict['cc0f1723-38d7-42da-aa2c-cef28d5f4250'] = '300'
flavordict['7447b146-eb66-4ecd-b8c9-ecf480fc6fd1'] = '300'
flavordict['6f43bc6c-c91e-4b4a-8981-dd1d06ec1bb7'] = '300'
flavordict['21e9047d-a60f-499d-b7f5-51f83ddf3611'] = '300'
flavordict['62a89635-8a60-40d7-9b58-56594a071b0a'] = '300'

instances = clients.allinstances(allregions=True)
i = 0
for instance in instances:
    if instance.flavor['id'] not in flavordict:
        print "flavordict missing %s?" % instance.flavor['id']
    else:
        print "%s, %s" % (instance.id, flavordict[instance.flavor['id']])
