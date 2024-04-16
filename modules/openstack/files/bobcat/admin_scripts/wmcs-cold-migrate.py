#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""
 cold-migrate stops an instance, moves it to a new host,
 and starts it.  It also has to twiddle with the nova
 db to update the virt host.

 Why does this work when all integrated nova migration
 methods don't?  It's a mystery.
"""

import argparse
import logging
import os
import subprocess
import sys
import time

import glanceclient
from keystoneauth1 import session as keystone_session
from keystoneauth1.identity.v3 import Password as KeystonePassword
from novaclient import client

if sys.version_info[0] >= 3:
    raw_input = input


class ScriptConfig:
    def __init__(
        self,
        datacenter,
        destination,
        mysql_password,
        nova_db_server,
        nova_db,
        cleanup,
        leak,
    ):
        self.datacenter = datacenter
        self.destination = destination
        self.datacenter = datacenter
        self.destination_fqdn = "{}.{}.wmnet".format(destination, datacenter)
        self.mysql_password = mysql_password
        self.nova_db_server = nova_db_server
        self.nova_db = nova_db
        if cleanup:
            self.cleanup = "cleanup"
        elif leak:
            self.cleanup = "leak"
        else:
            self.cleanup = ""


class NovaInstance(object):
    def __init__(self, session, instance_id, region):
        self.instance_id = instance_id
        self.session = session
        self.novaclient = client.Client("2", session=session, region_name=region)
        self.refresh_instance()

    # Returns True if the status changed, otherwise False
    def activate_image(self, image_id, deactivate=False):
        gclient = glanceclient.Client("2", session=session)
        image = gclient.images.get(image_id)
        changed = False

        logging.info("Needed image is {}".format(image.status))
        if deactivate:
            if image.status == "active":
                logging.info("deactivating image {}".format(image_id))
                gclient.images.deactivate(image_id)
                changed = True
        else:
            if image.status == "deactivated":
                logging.info("activating image {}".format(image_id))
                gclient.images.reactivate(image_id)
                changed = True

        return changed

    def refresh_instance(self):
        self.instance = self.novaclient.servers.get(self.instance_id)
        self.instance_name = self.instance._info["name"]

    def wait_for_status(self, desiredstatus):
        oldstatus = ""

        while self.instance.status != desiredstatus:
            if self.instance.status != oldstatus:
                oldstatus = self.instance.status
                logging.info(
                    "current status is {}; waiting for it to change to {}".format(
                        self.instance.status, desiredstatus
                    )
                )

            time.sleep(1)
            self.refresh_instance()

    def update_nova_db(self, config):
        mysql_password = config.mysql_password
        nova_db_server = config.nova_db_server
        nova_db = config.nova_db
        destination = config.destination
        destination_fqdn = config.destination_fqdn

        args = [
            "mysql",
            "--user=nova",
            "--password=%s" % mysql_password,
            "--port=3306",
            "--host",
            "%s" % nova_db_server,
            "%s" % nova_db,
            "-e",
            'update instances set host="%s",node="%s" '
            'where uuid="%s";' % (destination, destination_fqdn, self.instance_id),
        ]
        r = subprocess.call(args)
        if r:
            logging.error(
                "failed to update the instance's db record."
                "Host not moved. "
                "You will need to clean up files on {}".format(destination)
            )
            return False

        return True

    def instance_stop(self):
        if self.instance.status == "SHUTOFF":
            logging.warning("not stopping instance already in SHUTOFF state")
            return

        try:
            self.instance.stop()
            self.wait_for_status("SHUTOFF")
        except client.exceptions.Conflict as e:
            logging.error("failed to stop VM instance. Race condition?: {}".format(e))
            exit(1)

    def migrate(self, config):
        destination = config.destination
        destination_fqdn = config.destination_fqdn
        source = self.instance._info["OS-EXT-SRV-ATTR:host"]
        virshid = self.instance._info["OS-EXT-SRV-ATTR:instance_name"]
        source_fqdn = "{}.{}.wmnet".format(source, config.datacenter)

        logging.info(
            "instance {} ({}) is now on host {} with state {}".format(
                self.instance_id, self.instance_name, source, self.instance.status
            )
        )
        if source == destination:
            logging.warning("source and destination host are the same. Nothing to do.")
            exit(0)

        self.instance_stop()

        image_id = self.instance.image["id"]
        imagebasedir = "/var/lib/nova/instances"
        imagedir = "%s/%s" % (imagebasedir, self.instance_id)

        # ssh to the source host, and rsync from there to the dest
        #  using the shared nova key.
        #
        # Don't bother to rsync the console log.  Nova can't read
        #  it, and we don't need it.
        args = [
            "ssh",
            "-i",
            "/root/.ssh/compute-hosts-key",
            "nova@%s" % source_fqdn,
            '/usr/bin/rsync -S -avW -e "ssh -o Compression=no -o StrictHostKeyChecking=no '
            "-o UserKnownHostsFile=/dev/null -T -x -i "
            '/var/lib/nova/.ssh/id_rsa" --progress '
            "--exclude=console.log* "
            "%s nova@%s:%s" % (imagedir, destination_fqdn, imagebasedir),
        ]
        logging.info("{}".format(" ".join(args)))
        r = subprocess.call(args)
        if r:
            logging.error("rsync to new host failed.")
            return 1

        logging.info(
            "{} instance copied. Now updating nova db...".format(self.instance_name)
        )
        host_moved = self.update_nova_db(config)

        activated_image = self.activate_image(image_id)

        self.instance.start()
        self.wait_for_status("ACTIVE")

        if host_moved:
            logging.info("instance is active.")
            confirm = config.cleanup
            if confirm != "leak":
                while confirm != "cleanup":
                    confirm = raw_input(
                        "Verify that %s is healthy, then type "
                        "'cleanup' to delete old instance files:  "
                        % self.instance._info["name"]
                    )

                logging.info("removing old instance from libvirt on {}".format(source))
                undefine_args = [
                    "ssh",
                    "-i",
                    "/root/.ssh/compute-hosts-key",
                    "nova@%s" % source_fqdn,
                    "virsh",
                    "-c",
                    "qemu:///system",
                    "undefine",
                    virshid,
                ]
                undefine_status = subprocess.call(undefine_args)
                if undefine_status:
                    logging.error(
                        "undefine of {} on {} failed.".format(virshid, source)
                    )
                    return 1

                logging.info("cleaning up old instance files on {}".format(source))
                rmimage_args = [
                    "ssh",
                    "-i",
                    "/root/.ssh/compute-hosts-key",
                    "nova@%s" % source_fqdn,
                    "rm -rf",
                    imagedir,
                ]
                rmimage_status = subprocess.call(rmimage_args)
                if rmimage_status:
                    logging.error(
                        "cleanup of {} on {} failed.".format(imagedir, source)
                    )
                    return 1

        if activated_image:
            self.activate_image(image_id, deactivate=True)

        logging.info(
            "instance {} ({}) is now on host {} with status {}".format(
                self.instance_id,
                self.instance_name,
                self.instance._info["OS-EXT-SRV-ATTR:host"],
                self.instance.status,
            )
        )


if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "cold-migrate", description="Move an instance to a " "different compute node"
    )
    argparser.add_argument(
        "--nova-user",
        help="username for nova auth",
        default=os.environ.get("OS_USERNAME", None),
    )
    argparser.add_argument(
        "--nova-pass",
        help="password for nova auth",
        default=os.environ.get("OS_PASSWORD", None),
    )
    argparser.add_argument(
        "--nova-url",
        help="url for nova auth",
        default=os.environ.get("OS_AUTH_URL", None),
    )
    argparser.add_argument(
        "--nova-db-server",
        help="nova database server (FQDNs). Default is openstack.eqiad1.wikimediacloud.org",
        default="openstack.eqiad1.wikimediacloud.org",
    )
    argparser.add_argument(
        "--nova-db",
        help="nova database name. Default is nova_eqiad1",
        default="nova_eqiad1",
    )
    argparser.add_argument(
        "--region", help="nova region", default=os.environ.get("OS_REGION_NAME", None)
    )
    argparser.add_argument(
        "--mysql-password",
        help="mysql password for nova db",
        default=os.environ.get("NOVA_MYSQL_PASS", None),
    )
    argparser.add_argument("instanceid", help="instance id to migrate")
    argparser.add_argument("destination", help="destination host, e.g. labvirt1005")
    argparser.add_argument(
        "--datacenter",
        help="datacenter for operations, to calculate FQDNs. Default is eqiad",
        default="eqiad",
    )
    argparser.add_argument(
        "--cleanup",
        dest="cleanup",
        action="store_true",
        help="delete source VM without prompting",
    )
    argparser.add_argument(
        "--leak",
        dest="leak",
        action="store_true",
        help="exit without deleting source VM",
    )

    args = argparser.parse_args()

    if args.cleanup and args.leak:
        logging.error("--leak and --cleanup are mutually exclusive")
        exit(1)

    config = ScriptConfig(
        args.datacenter,
        args.destination,
        args.mysql_password,
        args.nova_db_server,
        args.nova_db,
        args.cleanup,
        args.leak,
    )
    logging.basicConfig(
        format="%(filename)s: %(levelname)s: %(message)s",
        level=logging.INFO,
        stream=sys.stdout,
    )

    sshargs = [
        "ssh",
        "-i",
        "/root/.ssh/compute-hosts-key",
        "nova@%s" % config.destination_fqdn,
        "true",
    ]
    r = subprocess.call(sshargs)
    if r:
        logging.error("remote execution failed; this whole enterprise is doomed.")
        exit(1)

    auth = KeystonePassword(
        auth_url=args.nova_url,
        username=args.nova_user,
        password=args.nova_pass,
        user_domain_name="Default",
        project_domain_name="Default",
        project_name="admin",
    )
    session = keystone_session.Session(auth=auth)

    instance = NovaInstance(session, args.instanceid, region=args.region)
    instance.migrate(config)
    logging.shutdown()
