#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""
 Suspend or resume all VMs in the cloud
 Disable or enable all hypervisors.

 When suspending, a list of suspended VMs is stored in the
 specified file; when resuming only VMs in the specified file
 are resumed. (This is to avoid messing up the state of VMs
 that were already suspended or otherwise inactive before
 this script was run)
"""

import argparse
import logging
import os
import sys

import mwopenstackclients
import novaclient.exceptions

if sys.version_info[0] >= 3:
    raw_input = input


if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "wmcs-pause-cloud", description="Disable all hypervisors and suspend all VMs"
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
    argparser.add_argument("--file", required=True, help="filepath to store suspended VMs")
    argparser.add_argument("--resume", action="store_true", help="resume VMs in referenced file")

    args = argparser.parse_args()

    logging.basicConfig(
        format="%(filename)s: %(asctime)s: %(levelname)s: %(message)s",
        level=logging.INFO,
        stream=sys.stdout,
    )

    osclients = mwopenstackclients.clients()
    nova = osclients.novaclient()

    if not args.resume:
        # disable all hypervisors so we don't get new VMs
        #  spinning up in the middle of whatever we're doing
        servicelist = nova.services.list()
        for service in servicelist:
            if service.binary == "nova-compute":
                logging.info("Disabling nova-compute on " + service.host)
                nova.services.disable(service.host, service.binary)

    # First dump all active VMs into the specified file
    all_instances = nova.servers.list(search_opts={"all_tenants": True})

    if not args.resume:
        if os.path.isfile(args.file):
            logging.error(
                "%s already exists; not overwriting it out of an abundance of caution." % args.file
            )
            exit(1)
        with open(args.file, "w") as idfile:
            for instance in all_instances:
                if instance.status == "ACTIVE":
                    idfile.write(instance.id + "\n")

    instancelistfile = open(args.file, "r")
    instancelist = instancelistfile.readlines()
    instancelistfile.close()

    if args.resume:
        for instanceline in instancelist:
            instanceid = instanceline.strip()
            try:
                nova.servers.resume(instanceid)
            except novaclient.exceptions.Conflict as e:
                logging.warning(e)
            else:
                logging.info("Resuming " + instanceid)
    else:
        for instanceline in instancelist:
            instanceid = instanceline.strip()
            try:
                nova.servers.suspend(instanceid)
            except novaclient.exceptions.Conflict as e:
                logging.warning(e)
            else:
                logging.info("Suspending " + instanceid)

    if args.resume:
        # enable all hypervisors
        servicelist = nova.services.list()
        for service in servicelist:
            if service.binary == "nova-compute":
                logging.info("Enabling nova-compute on " + service.host)
                nova.services.enable(service.host, service.binary)

    logging.shutdown()
    exit(0)
