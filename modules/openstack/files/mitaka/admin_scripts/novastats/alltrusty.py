#!/usr/bin/python

import mwopenstackclients

clients = mwopenstackclients.clients()

images = clients.globalimages()
trustyimages = [image.id for image in images if 'trusty' in image.name.lower()]
jessieimages = [image.id for image in images if 'jessie' in image.name.lower()]

instances = clients.allinstances(allregions=True)
i = 0
jessiecount = 0
active = 0
nagworthy = 0

for instance in instances:
    if instance.image['id'] in trustyimages:
        i += 1
        if instance.status.lower() == 'active':
            active += 1
            if instance.tenant_id == 'tools':
                continue
            if instance.tenant_id == 'integration':
                continue
            nagworthy += 1

    if instance.image['id'] in jessieimages:
        jessiecount += 1

print "   %d trusty instances exist." % i
print "   %d trusty instances are running." % active
print "   %d trusty instances are running outside of tools and integration." % nagworthy
print "   %d jessie instances exist." % jessiecount
