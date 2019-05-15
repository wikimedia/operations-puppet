#!/usr/bin/python
"""
 cold-migrate stops an instance, moves it to a new host,
 and starts it.  It also has to twiddle with the nova
 db to update the virt host.

 Why does this work when all integrated nova migration
 methods don't?  It's a mystery.
"""

import argparse
import os
import requests
import subprocess
import time
import logging
import sys

import glanceclient
from keystoneclient.auth.identity import generic
from keystoneclient import session as keystone_session
from novaclient import client


class ScriptConfig():

    def __init__(self, datacenter, destination, mysql_password, nova_db_server, nova_db):
        self.datacenter = datacenter
        self.destination = destination
        self.destination_fqdn = '{}.{}.wmnet'.format(destination, datacenter)
        self.mysql_password = mysql_password
        self.nova_db_server = nova_db_server
        self.nova_db = nova_db


class NovaInstance(object):

    def __init__(self, session, instance_id, region):
        self.instance_id = instance_id
        self.session = session
        self.novaclient = client.Client('2', session=session, region_name=region)
        self.refresh_instance()

    # Returns True if the status changed, otherwise False
    def activate_image(self, image_id, deactivate=False):
        token = self.session.get_token()

        glanceendpoint = self.session.get_endpoint(service_type='image')
        gclient = glanceclient.Client('1', glanceendpoint, token=token)
        image = gclient.images.get(image_id)

        # Because the glance devs can't be bothered to update their python
        #  bindings when new features are added, we have to do this the
        #  old-fasioned way.
        logging.info("Needed image is {}".format(image.status))
        if deactivate:
            action = 'deactivate'
            if image.status == 'deactivated':
                # Nothing to do
                return False
            logging.info("deactivating image {}".format(image_id))
        else:
            action = 'reactivate'
            if image.status == 'active':
                # Nothing to do
                return False
            logging.info("activating image {}".format(image_id))

        url = "%s/v2/images/%s/actions/%s" % (glanceendpoint, image_id, action)

        resp = requests.post(url, headers={'X-Auth-Token': token})
        if resp:
            return True
        else:
            raise Exception("Image manipulation got status: " + resp.status_code)

    def refresh_instance(self):
        self.instance = self.novaclient.servers.get(self.instance_id)
        self.instance_name = self.instance._info['name']

    def wait_for_status(self, desiredstatus):
        oldstatus = ""

        while self.instance.status != desiredstatus:
            if self.instance.status != oldstatus:
                oldstatus = self.instance.status
                logging.info("current status is {}; waiting for it to change to {}".format(
                             self.instance.status, desiredstatus))

            time.sleep(1)
            self.refresh_instance()

    def update_nova_db(self, config):
        mysql_password = config.mysql_password
        nova_db_server = config.nova_db_server
        nova_db = config.nova_db
        destination = config.destination
        destination_fqdn = config.destination_fqdn

        args = ["mysql", "--user=nova", "--password=%s" % mysql_password,
                "--host", "%s" % nova_db_server, "%s" % nova_db,
                "-e",
                "update instances set host=\"%s\",node=\"%s\" "
                "where uuid=\"%s\";" %
                (destination, destination_fqdn, self.instance_id)]
        r = subprocess.call(args)
        if r:
            logging.error("failed to update the instance's db record."
                          "Host not moved. "
                          "You will need to clean up files on {}".format(destination))
            return False

        return True

    def instance_stop(self):
        if self.instance.status == 'SHUTOFF':
            logging.warning("not stopping instance already in SHUTOFF state")
            return

        try:
            self.instance.stop()
            self.wait_for_status('SHUTOFF')
        except client.exceptions.Conflict as e:
            logging.error("failed to stop VM instance. Race condition?: {}".format(e))
            exit(1)

    def migrate(self, config):
        destination = config.destination
        destination_fqdn = config.destination_fqdn
        source = self.instance._info['OS-EXT-SRV-ATTR:host']
        source_fqdn = '{}.{}.wmnet'.format(source, config.datacenter)

        logging.info("instance {} ({}) is now on host {} with state {}".format(
                     self.instance_id, self.instance_name, source, self.instance.status))
        if (source == destination):
            logging.warning("source and destination host are the same. Nothing to do.")
            exit(0)

        self.instance_stop()

        image_id = self.instance.image['id']
        imagebasedir = "/var/lib/nova/instances"
        imagedir = "%s/%s" % (imagebasedir, self.instance_id)

        # ssh to the source host, and rsync from there to the dest
        #  using the shared nova key.
        #
        # Don't bother to rsync the console log.  Nova can't read
        #  it, and we don't need it.
        args = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                "nova@%s" % source_fqdn,
                "/usr/bin/rsync -S -avW -e \"ssh -o Compression=no -o StrictHostKeyChecking=no "
                "-o UserKnownHostsFile=/dev/null -T -x -i "
                "/var/lib/nova/.ssh/id_rsa\" --progress "
                "--exclude=console.log* "
                "%s nova@%s:%s" %
                (imagedir, destination_fqdn, imagebasedir)]
        logging.info("{}".format(" ".join(args)))
        r = subprocess.call(args)
        if r:
            logging.error("rsync to new host failed.")
            return(1)

        logging.info("{} instance copied. Now updating nova db...".format(self.instance_name))
        host_moved = self.update_nova_db(config)

        activated_image = self.activate_image(image_id)

        self.instance.start()
        self.wait_for_status('ACTIVE')

        if host_moved:
            logging.info("instance is active.")
            confirm = ""
            while (confirm != "cleanup"):
                confirm = raw_input(
                    "Verify that the instance is healthy, then type "
                    "'cleanup' to delete old instance files:  ")
            logging.info("cleaning up old instance files on {}".format(source))
            args = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                    "nova@%s" % source_fqdn,
                    "rm -rf", imagedir]
            r = subprocess.call(args)
            if r:
                logging.error("cleanup of {} on {} failed.".format(imagedir, source))
                return(1)

        if activated_image:
            self.activate_image(image_id, deactivate=True)

        logging.info("instance {} ({}) is now on host {} with status {}".format(
                     self.instance_id,
                     self.instance_name,
                     self.instance._info['OS-EXT-SRV-ATTR:host'],
                     self.instance.status))


if __name__ == "__main__":
    argparser = argparse.ArgumentParser('cold-migrate',
                                        description="Move an instance to a "
                                        "different compute node")
    argparser.add_argument(
        '--nova-user',
        help='username for nova auth',
        default=os.environ.get('OS_USERNAME', None)
    )
    argparser.add_argument(
        '--nova-pass',
        help='password for nova auth',
        default=os.environ.get('OS_PASSWORD', None)
    )
    argparser.add_argument(
        '--nova-url',
        help='url for nova auth',
        default=os.environ.get('OS_AUTH_URL', None)
    )
    argparser.add_argument(
        '--nova-db-server',
        help='nova database server (FQDNs). Default is m5-master.eqiad.wmnet',
        default="m5-master.eqiad.wmnet"
    )
    argparser.add_argument(
        '--nova-db',
        help='nova database name. Default is nova_eqiad1',
        default="nova_eqiad1"
    )
    argparser.add_argument(
        '--region',
        help='nova region',
        default=os.environ.get('OS_REGION_NAME', None)
    )
    argparser.add_argument(
        '--mysql-password',
        help='mysql password for nova db',
        default=os.environ.get('NOVA_MYSQL_PASS', None)
    )
    argparser.add_argument(
        'instanceid',
        help='instance id to migrate',
    )
    argparser.add_argument(
        'destination',
        help='destination host, e.g. labvirt1005',
    )
    argparser.add_argument(
        '--datacenter',
        help='datacenter for operations, to calculate FQDNs. Default is eqiad',
        default="eqiad"
    )

    args = argparser.parse_args()

    config = ScriptConfig(args.datacenter, args.destination, args.mysql_password,
                          args.nova_db_server, args.nova_db)
    logging.basicConfig(format="%(filename)s: %(levelname)s: %(message)s",
                        level=logging.INFO, stream=sys.stdout)

    sshargs = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
               "nova@%s" % config.destination_fqdn, "true"]
    r = subprocess.call(sshargs)
    if r:
        logging.error("remote execution failed; this whole enterprise is doomed.")
        exit(1)

    auth = generic.Password(
        auth_url=args.nova_url,
        username=args.nova_user,
        password=args.nova_pass,
        user_domain_name='Default',
        project_domain_name='Default',
        project_name='admin')
    session = keystone_session.Session(auth=auth)

    instance = NovaInstance(session, args.instanceid, region=args.region)
    instance.migrate(config)
    logging.shutdown()
