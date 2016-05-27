#!/usr/bin/python

import subprocess


def checkSalt(ec2ID, site="eqiad"):
    hostname = "%s.%s.wmflabs" % (ec2ID, site)
    args = ["salt", hostname, "test.ping"]
    r = subprocess.check_output(args)
    if r.find("No minions matched the target") >= 0:
        return "missing"
    if r.find("True") >= 0:
        return "up"
    else:
        return "down"


def checkMatch(ec2ID, needle, haystackPath, site="eqiad"):
    hostname = "%s.%s.wmflabs" % (ec2ID, site)
    args = ["salt", hostname, "file.search", haystackPath, needle]
    try:
        r = subprocess.check_output(args)
        if r.find("True") >= 0:
            return "found"
        if r.find("False") >= 0:
            return "missing"
        return "failed"
    except subprocess.CalledProcessError:
        return "failed"


def checkMatchSsh(ec2ID, needle, haystackPath, site="eqiad"):
    hostname = "%s.%s.wmflabs" % (ec2ID, site)
    args = ["salt", hostname, "file.search", haystackPath, needle]
    try:
        r = subprocess.check_output(args)
        if r.find("True") >= 0:
            return "found"
        if r.find("False") >= 0:
            return "missing"
        return "failed"
    except subprocess.CalledProcessError:
        return "failed"


def instanceDetails(instanceID):
    detailDict = {}
    args = ["nova", "show", instanceID]
    try:
        novaDetails = subprocess.check_output(args)
        detailLines = novaDetails.split("\n")
        for detailLine in detailLines:
            detailFields = detailLine.split('|')
            if len(detailFields) < 2:
                continue
            key = detailFields[1].strip()
            value = detailFields[2].strip()
            detailDict[key] = value
    except subprocess.CalledProcessError:
        print "Unable to 'nova show' %s" % instanceID
        return False

    return detailDict


def imageData():
    args = ["nova", "image-list"]
    imagelist = subprocess.check_output(args)
    images = {}

    for image in imagelist.split('\n'):
        if image.startswith("+"):
            continue
        if image.startswith("| ID"):
            continue
        imageFields = image.split('|')
        if len(imageFields) < 2:
            continue

        imageDict = {}
        imageID = imageFields[1].strip()

        imageDict["status"] = imageFields[2].strip()
        imageDict["name"] = imageFields[1].strip()
        images[imageID] = imageDict

    return images


def instanceData(tenantName=None):
    if tenantName:
        args = ["nova", "--os-tenant-id", tenantName, "list"]
    else:
        args = ["nova", "list", "--all-tenants"]

    instancelist = subprocess.check_output(args)

    instances = {}

    for instance in instancelist.split('\n'):
        if instance.startswith("+"):
            continue
        if instance.startswith("| ID"):
            continue
        instanceFields = instance.split('|')
        if len(instanceFields) < 2:
            continue

        instanceID = instanceFields[1].strip()

        instanceDict = instanceDetails(instanceID)
        if instanceDict:
            instanceDict["status"] = instanceFields[3].strip()
            instanceDict["networks"] = instanceFields[6].strip()
            instances[instanceID] = instanceDict

    return instances
