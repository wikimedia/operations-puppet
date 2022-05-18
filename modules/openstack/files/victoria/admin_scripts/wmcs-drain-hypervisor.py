#!/usr/bin/python3
"""
 Migrate all VMs off a given hypervisor, one at a time.

 This doesn't take a requested destination; we let the nova
 scheduler decide where to put things.

 Note that if you don't want new VMs flooding back onto the
 hypervisor while draining you will need to adjust its membership
 in host aggregates. This script doesn't automate that so we don't
 lose track of how the hypervisor was assigned beforehand.
"""

import argparse
import logging
import os
import sys
import time

import mwopenstackclients
import novaclient.exceptions

CANARY_PROJECT = "cloudvirt-canary"


if sys.version_info[0] >= 3:
    raw_input = input


def _is_canary(instance):
    return instance.tenant_id == CANARY_PROJECT


class NovaInstance(object):
    def __init__(self, osclients, instance_id):
        self.instance_id = instance_id
        self.osclients = osclients
        self.novaclient = self.osclients.novaclient()
        self.refresh_instance()

    def refresh_instance(self):
        self.instance = self.novaclient.servers.get(self.instance_id)
        self.instance_name = self.instance._info["name"]

    def wait_for_status(self, desiredstatuses, timeout=60):
        oldstatus = ""
        elapsed = 0
        naplength = 1

        while self.instance.status not in desiredstatuses:
            if self.instance.status != oldstatus:
                oldstatus = self.instance.status
                logging.info(
                    "current status is {}; waiting for it to change to {}".format(
                        self.instance.status, desiredstatuses
                    )
                )

            time.sleep(naplength)
            elapsed += naplength

            if elapsed > timeout:
                # Since we don't actually check the clock, the timeout values
                #  here are a approximate. If someone determines that sub-second
                #  timeout accuracy is important we can add an actual clock read
                #  here.
                raise TimeoutError()

            self.refresh_instance()

    def stopped_migrate(self):
        logging.info("Migrating stopped VM %s (%s)" % (self.instance.name, self.instance.id))
        self.instance.migrate()
        # Currently (Openstack Train) a cold migrate is implemented as a resize.
        #  I'm checking for alternate statuses here in case someone fixes that
        #  someday to report a more reasonable status
        self.wait_for_status(["MIGRATING", "RESIZE"])
        self.wait_for_status(["SHUTOFF", "ACTIVE", "VERIFY_RESIZE"], timeout=300)
        if self.instance.status == "VERIFY_RESIZE":
            self.instance.confirm_resize()
            self.wait_for_status(["SHUTOFF", "ACTIVE"])
        logging.info(
            "instance {} ({}) is now on host {} with status {}".format(
                self.instance_id,
                self.instance_name,
                self.instance._info["OS-EXT-SRV-ATTR:host"],
                self.instance.status,
            )
        )

    def paused_migrate(self):
        logging.info("Migrating paused VM %s (%s)" % (self.instance.name, self.instance.id))
        self.instance.unpause()
        self.wait_for_status(["ACTIVE"])
        self.live_migrate()
        self.instance.pause()
        self.wait_for_status(["PAUSED"])

    def live_migrate(self):
        logging.info("Migrating %s (%s)" % (self.instance.name, self.instance.id))
        self.instance.live_migrate()
        self.wait_for_status(["MIGRATING"])
        self.wait_for_status(["ACTIVE"], timeout=1200)
        logging.info(
            "instance {} ({}) is now on host {} with status {}".format(
                self.instance_id,
                self.instance_name,
                self.instance._info["OS-EXT-SRV-ATTR:host"],
                self.instance.status,
            )
        )

    def migrate(self):
        try:
            if self.instance.status == "ACTIVE":
                self.live_migrate()
            elif self.instance.status == "SHUTOFF":
                self.stopped_migrate()
            elif self.instance.status == "PAUSED":
                self.paused_migrate()
            else:
                logging.info(
                    "instance {} ({}) is in state {} which this script can't handle."
                    " Skipping.".format(self.instance_id, self.instance_name, self.instance.status)
                )
                return False
        except TimeoutError:
            logging.warning(
                "Timed out during migration of instance {} ({})".format(
                    self.instance_id, self.instance_name
                )
            )
            return False
        except novaclient.exceptions.BadRequest as exc:
            logging.warning(
                "Failed to migrate instance {} ({}): {}".format(
                    self.instance_id, self.instance_name, exc
                )
            )
            return False

        return True


if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "wmcs-drain-hypervisor", description="Move all VMs off a given hypervisor"
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
    argparser.add_argument("hypervisor", help="name of hypervisor to drain")

    args = argparser.parse_args()

    logging.basicConfig(
        format="%(filename)s: %(asctime)s: %(levelname)s: %(message)s",
        level=logging.INFO,
        stream=sys.stdout,
    )

    osclients = mwopenstackclients.clients()
    nova = osclients.novaclient()

    retries = 1
    for attempt in range(1, retries + 2):
        all_instances = nova.servers.list(
            search_opts={"host": args.hypervisor, "all_tenants": True}
        )
        remaining_instances = list(all_instances)

        for instance in all_instances:
            if _is_canary(instance):
                logging.info("Igoring canary instance %s (%s)" % (instance.name, instance.id))
                # Leave the canary behind; it won't do any good anywhere else
                remaining_instances.remove(instance)
                continue
            instanceobj = NovaInstance(osclients, instance.id)
            if instanceobj.migrate():
                if instanceobj.instance._info["OS-EXT-SRV-ATTR:host"] == args.hypervisor:
                    logging.warning(
                        f"{instanceobj.instance_name} ({instanceobj.instance_id}) didn't actually "
                        "migrate, got scheduled on the same hypervisor. Will try again!"
                    )
                else:
                    remaining_instances.remove(instance)

        if remaining_instances:
            logging.warning(
                "On drain attempt #%d we failed to migrate %d instances."
                % (attempt, len(remaining_instances))
            )
        else:
            break

    remaining_instances = []
    all_instances = nova.servers.list(search_opts={"host": args.hypervisor, "all_tenants": True})
    for instance in all_instances:
        if not _is_canary(instance):
            logging.warning(
                "Failed to migrate %s.%s (%s)" % (instance.name, instance.tenant_id, instance.id)
            )
            remaining_instances.append(instance)

    logging.shutdown()

    if remaining_instances:
        exit(1)

    exit(0)
