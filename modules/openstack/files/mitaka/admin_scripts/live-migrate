#!/usr/bin/python
"""
 live-migrate is a wrapper around nova's built-in block migrate
 service.

 A standard block-migrate has the side-effect of expanding our
 compact qcow2 instances and gobbling disk space.  This script
 block-migrates but then suspends and re-compresses the instances
 after arrival.

 Live migration will cause service interruption on instances
 during the suspension, but does not manifest as a reboot
 on the instance.
"""

import argparse
import time
import subprocess

from novaclient.v1_1 import client


class NovaInstance(object):

    def __init__(self, novaclient, instance_id):
        self.novaclient = novaclient
        self.instance_id = instance_id
        self.refresh_instance()

    def refresh_instance(self):
        self.instance = self.novaclient.servers.get(self.instance_id)

    def wait_for_status(self, desiredstatus):
        oldstatus = ""

        while self.instance.status != desiredstatus:
            if self.instance.status != oldstatus:
                oldstatus = self.instance.status
                print "Current status is %s; waiting for it to change to %s." % (
                    self.instance.status, desiredstatus)

            time.sleep(1)
            self.refresh_instance()

    def migrate(self, destination):
        print "Instance %s is now on host %s with state %s" % (
            self.instance_id,
            self.instance._info['OS-EXT-SRV-ATTR:host'],
            self.instance.status)

        self.instance.live_migrate(destination, True, True)
        self.wait_for_status('MIGRATING')
        self.wait_for_status('ACTIVE')

        if self.instance.status != 'ACTIVE':
            print "Failed to migrate instance, best to check by hand and see what happened."
            return(1)

        imagedir = "/var/lib/nova/instances/%s" % self.instance_id
        former = "%s/disk.big" % imagedir
        future = "%s/disk" % imagedir

        args = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                "nova@%s.eqiad.wmnet" % destination,
                "ls", future]
        r = subprocess.call(args)
        if r:
            print ("Instance migrated but has unusual disk arrangement, so there will be "
                   "no post-migration shrinking.")
            return(0)

        print "Instance has migrated.  Now suspending and recompressing..."
        self.instance.suspend()
        self.wait_for_status('SUSPENDED')

        args = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                "nova@%s.eqiad.wmnet" % destination,
                "mv", future, former]
        r = subprocess.call(args)
        if r:
            print "Unable to backup the instance's disk; aborting."
            return(1)

        args = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                "nova@%s.eqiad.wmnet" % destination,
                "qemu-img", "convert", "-O", "qcow2",
                former, future]
        r = subprocess.call(args)
        if r:
            print "Failed to recompress the original image.  Possible disaster."
            return(1)

        args = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                "nova@%s.eqiad.wmnet" % destination,
                "rm", former]
        r = subprocess.call(args)
        if r:
            print "Failed to clean up the original uncompressed disk image.  Weird."
            return(1)

        self.instance.resume()
        self.wait_for_status('ACTIVE')

        print
        print "Instance %s is now on host %s with status %s" % (
            self.instance_id,
            self.instance._info['OS-EXT-SRV-ATTR:host'],
            self.instance.status)


if __name__ == "__main__":
    argparser = argparse.ArgumentParser('live-migrate',
                                        description='''Move an instance to a different compute node''')
    argparser.add_argument(
        '--nova-user',
        help='username for nova auth',
        default='novaadmin'
    )
    argparser.add_argument(
        '--nova-pass',
        help='password for nova auth',
        required=True,
    )
    argparser.add_argument(
        '--nova-url',
        help='url for nova auth',
        default='http://cloudcontrol1003.wikimedia.org:35357/v2.0'
    )
    argparser.add_argument(
        '--nova-project',
        help='project for nova auth',
        default='admin'
    )
    argparser.add_argument(
        'instanceid',
        help='instance id to migrate',
    )
    argparser.add_argument(
        'destination',
        help='destination host, e.g. labvirt1005',
    )
    args = argparser.parse_args()

    sshargs = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
               "nova@%s.eqiad.wmnet" % args.destination, "true"]
    r = subprocess.call(sshargs)
    if r:
        print "Remote execution failed; this whole enterprise is doomed."
        exit(1)

    novaclient = client.Client(args.nova_user,
                               args.nova_pass,
                               args.nova_project,
                               args.nova_url)

    instance = NovaInstance(novaclient, args.instanceid)
    instance.migrate(args.destination)
