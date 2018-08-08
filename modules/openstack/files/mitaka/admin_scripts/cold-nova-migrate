#!/usr/bin/python
"""
 cold-nova-migrate is a not-very-smart wrapper around the standard
 'nova migrate' feature.  As documented, nova migration requires
 several steps, each of which includes 'wait until status is...'
 so it's not especially useful for batch applications.  This
 script should be reliable for running multiple migrations
 in sequence.

 cold-migrate performs the following steps, polling for a proper
 instance status after each:

  - Stop instance
  - Migrate instance
  - Confirm migration (oddly called 'confirm resize' in nova parlance)
  - Restart instance (optional)
"""

import argparse
import time

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

    def migrate(self, leave_stopped=False):
        print "Instance %s is now on host %s with state %s" % (
            self.instance_id,
            self.instance._info['OS-EXT-SRV-ATTR:host'],
            self.instance.status)

        if self.instance.status != 'SHUTOFF':
            self.instance.stop()
            self.wait_for_status('SHUTOFF')

        if self.instance.status != 'SHUTOFF':
            print "Failed to stop instance, aborting."
            exit(1)

        self.instance.migrate()
        self.wait_for_status('VERIFY_RESIZE')

        if self.instance.status != 'VERIFY_RESIZE':
            print "Failed to migrate instance, aborting."
            exit(1)

        self.instance.confirm_resize()
        self.wait_for_status('SHUTOFF')

        if self.instance.status != 'SHUTOFF':
            print "Failed to confirm migrate, aborting."
            exit(1)

        if not leave_stopped:
            self.instance.start()
            self.wait_for_status('ACTIVE')

        print
        print "Instance %s is now on host %s with status %s" % (
            self.instance_id,
            self.instance._info['OS-EXT-SRV-ATTR:host'],
            self.instance.status)


if __name__ == "__main__":
    argparser = argparse.ArgumentParser('cold-migrate',
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
        '--no-restart',
        help='Do not start instance after migrate',
        default=False
    )
    argparser.add_argument(
        'instanceid',
        help='instance id to migrate',
        default='testlabs'
    )
    args = argparser.parse_args()

    novaclient = client.Client(args.nova_user,
                               args.nova_pass,
                               args.nova_project,
                               args.nova_url)

    instance = NovaInstance(novaclient, args.instanceid)
    instance.migrate(args.no_restart)
