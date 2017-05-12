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
flavordict['cc0f1723-38d7-42da-aa2c-cef28d5f4250'] = '300'

instances = clients.allinstances()
i = 0
for instance in instances:
    if instance.flavor['id'] not in flavordict:
        print "flavordict missing %s?" % instance.flavor['id']
    else:
        print "%s, %s" % (instance.id, flavordict[instance.flavor['id']])
