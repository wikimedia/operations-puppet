#!/usr/bin/python

import argparse
import mwopenstackclients

parser = argparse.ArgumentParser(description='Learn about image usage.')
parser.add_argument('--project',
                    dest='project',
                    help='limit stats to a single project',
                    default=None)
parser.add_argument('--imageid',
                    dest='imageid',
                    help='Check usage of the specified image',
                    default=None)
args = parser.parse_args()

allinstances = mwopenstackclients.Clients().allinstances(args.project, allregions=True)
bigDict = {instance.id: instance for instance in allinstances}

usedimages = set()
activeimages = set()
usinginstances = []

imagelist = mwopenstackclients.Clients().globalimages()
images = {image.id: image for image in imagelist}
allimages = set(images.keys())

for ID in bigDict.keys():
    instance = bigDict[ID]

    imageid = instance.image['id']

    usedimages.add(imageid)
    if instance.status == "ACTIVE":
        activeimages.add(imageid)

    if args.imageid:
        if imageid == args.imageid:
            usinginstances.append([ID,
                                   instance.name,
                                   instance.tenant_id])


orphanimages = allimages.difference(usedimages)
stoppedimages = allimages.difference(activeimages).difference(orphanimages)

if args.imageid:
    print "The image %s is used by the following instances:" % args.imageid
    for instance in usinginstances:
        print "%s %s %s" % (instance[0], instance[1], instance[2])
else:
    print "All images:"
    for imagename in images:
        print imagename

    print "Unused images:"
    for imagename in orphanimages:
        print imagename

    print "images used only for stopped or error instances:"
    for imagename in stoppedimages:
        print imagename
