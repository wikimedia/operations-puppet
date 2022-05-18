#!/usr/bin/python3
"""
 ceph-migrate stops an instance, converts its disk image to
 'raw', copies the data to ceph, and restarts the host
 on a ceph-enabled hypervisor.
"""

import argparse
import logging
import os
import subprocess
import sys
import time

import mwopenstackclients
from novaclient import client

if sys.version_info[0] >= 3:
    raw_input = input


# In order to impose proper throttling, each VM will
#  be 'resized' after migration.  In reality the new flavor
#  has the same specs as the old, but with disk use limits.
flavor_map = {
    "ci1.medium": "g2.cores2.ram2.disk40",
    "justdisk": "g2.cores4.ram8.disk300",
    "parsingtest": "g2.cores12.ram32.disk400",
    "c8.m8.s60": "g2.cores8.ram8.disk60",
    "m1.gigantic": "g2.cores16.ram16.disk80",
    "c1.m2.s80": "g2.cores1.ram2.disk80",
    "xlarge-xtradisk": "g2.cores8.ram16.disk300",
    "bigdisk2": "g2.cores4.ram24.disk300",
    "bigram": "g2.cores8.ram36.disk80",
    "mediumram": "g2.cores8.ram24.disk80",
    "m1.xlarge": "g2.cores8.ram16.disk160",
    "m1.large": "g2.cores4.ram8.disk80",
    "m1.medium": "g2.cores2.ram4.disk40",
    "m1.small": "g2.cores1.ram2.disk20",
}


class ScriptConfig:
    def __init__(
        self, datacenter, destination, mysql_password, nova_db_server, nova_db, cleanup, leak
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
    def __init__(self, instance_id, region):
        self.instance_id = instance_id
        self.osclients = mwopenstackclients.clients()
        self.novaclient = self.osclients.novaclient()
        self.refresh_instance()

        nova = self.osclients.novaclient()
        flavors = nova.flavors.list()
        flavoriddict = {f.id: f.name for f in flavors}
        flavornamedict = {f.name: f.id for f in flavors}

        projects = self.osclients.allprojects()
        for project in projects:
            nova_per_project = self.osclients.novaclient(project.id)
            project_flavors = nova_per_project.flavors.list()
            for project_flavor in project_flavors:
                if project_flavor.id not in flavoriddict:
                    flavornamedict[project_flavor.name] = project_flavor.id
                    flavoriddict[project_flavor.id] = project_flavor.name

        source_flavor_name = flavoriddict[self.instance.flavor["id"]]
        dest_flavor_name = flavor_map[source_flavor_name]
        self.dest_flavor_id = flavornamedict[dest_flavor_name]
        logging.warning(
            "We will convert to flavor %s (%s)" % (dest_flavor_name, self.dest_flavor_id)
        )

    # Returns True if the status changed, otherwise False
    def activate_image(self, image_id, deactivate=False):
        gclient = self.osclients.glanceclient()
        print("image_id is %s" % image_id)
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
        source = self.instance._info["OS-EXT-SRV-ATTR:host"]
        virshid = self.instance._info["OS-EXT-SRV-ATTR:instance_name"]
        instance_fqdn = "{}.{}.{}.wmflabs".format(
            self.instance._info["name"], self.instance._info["tenant_id"], config.datacenter
        )
        source_fqdn = "{}.{}.wmnet".format(source, config.datacenter)

        logging.info(
            "instance {} ({}) is now on host {} with state {}".format(
                self.instance_id, self.instance_name, source, self.instance.status
            )
        )

        self.instance_stop()

        image_id = self.instance.image["id"]
        imagebasedir = "/var/lib/nova/instances"
        imagedir = "%s/%s" % (imagebasedir, self.instance_id)

        # ssh to the source host, convert image and import to ceph
        args = [
            "ssh",
            "-i",
            "/root/.ssh/compute-hosts-key",
            "nova@%s" % source_fqdn,
            "qemu-img convert -f qcow2 -O raw %s/disk "
            "rbd:eqiad1-compute/%s_disk:id=eqiad1-compute" % (imagedir, self.instance_id),
        ]

        logging.info("{}".format(" ".join(args)))
        r = subprocess.call(args)
        if r:
            logging.error("copy to ceph failed.")
            return 1

        logging.info("{} instance copied. Now updating nova db...".format(self.instance_name))
        host_moved = self.update_nova_db(config)

        if host_moved:
            activated_image = self.activate_image(image_id)
            self.instance.start()
            self.wait_for_status("ACTIVE")
            self.instance.resize(self.dest_flavor_id)
            self.wait_for_status("VERIFY_RESIZE")

            logging.info("instance is active.")
            confirm = config.cleanup
            if confirm != "leak":
                while confirm != "cleanup":
                    confirm = raw_input(
                        "Verify that %s is healthy, then type "
                        "'cleanup' to delete old instance files:  " % instance_fqdn
                    )

                logging.info("confirming resize")
                self.instance.confirm_resize()
                self.wait_for_status("ACTIVE")
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
                    logging.error("undefine of {} on {} failed.".format(virshid, source))
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
                    logging.error("cleanup of {} on {} failed.".format(imagedir, source))
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
        "--nova-user", help="username for nova auth", default=os.environ.get("OS_USERNAME", None)
    )
    argparser.add_argument(
        "--nova-pass", help="password for nova auth", default=os.environ.get("OS_PASSWORD", None)
    )
    argparser.add_argument(
        "--nova-url", help="url for nova auth", default=os.environ.get("OS_AUTH_URL", None)
    )
    argparser.add_argument(
        "--nova-db-server",
        help="nova database server (FQDNs). Default is m5-master.eqiad.wmnet",
        default="openstack.eqiad1.wikimediacloud.org",
    )
    argparser.add_argument(
        "--nova-db", help="nova database name. Default is nova_eqiad1", default="nova_eqiad1"
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
        "--cleanup", dest="cleanup", action="store_true", help="delete source VM without prompting"
    )
    argparser.add_argument(
        "--leak", dest="leak", action="store_true", help="exit without deleting source VM"
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
        format="%(filename)s: %(levelname)s: %(message)s", level=logging.INFO, stream=sys.stdout
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

    instance = NovaInstance(args.instanceid, region=args.region)

    instance.migrate(config)
    logging.shutdown()
