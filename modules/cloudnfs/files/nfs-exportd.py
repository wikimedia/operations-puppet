#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2016 Wikimedia Foundation, Inc.
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
#
#  THIS FILE IS MANAGED BY PUPPET
#

import ipaddress
import argparse
import yaml
import os
import time
import logging
from netifaces import interfaces, ifaddresses, AF_INET
import sys
import socket
import subprocess


from keystoneauth1.exceptions.http import Unauthorized
from keystoneauth1.identity.v3 import Password as KeystonePassword
from keystoneauth1.session import Session as KeystoneSession
from keystoneclient.v3 import client as keystone_client

from novaclient import client as novaclient


def is_valid_ipv4(ip):
    """
    Returns true if ip is a valid ipv4 address
    """
    try:
        ipaddress.IPv4Address(ip)
        return True
    except ipaddress.AddressValueError:
        return False


class Project:
    """ async -- io should be done asynchronously
        no_root_squash -- allow root in project instances
                          to be treated as root on mount
    """

    EXPORTS_TEMPLATE = (
        "{mountpoint} "
        + "-rw,nohide,no_subtree_check,async,no_root_squash "
        + "{instance_ips}"
    )

    def __init__(self, name, gid, instance_ips, mountpoints):
        self.name = name
        self.instance_ips = instance_ips
        self.mountpoints = mountpoints
        self.gid = gid

    def get_exports(self):
        exportlines = []
        for mountpoint in self.mountpoints:
            exportlines.append(
                Project.EXPORTS_TEMPLATE.format(
                    mountpoint=mountpoint, instance_ips=" ".join(self.instance_ips)
                )
            )

        return "\n".join(exportlines)


def get_instance_ips(project, observer_pass, regions, auth_url):
    """
    Return a list of Instance internal IPs for a given project

    This uses the Nova API to fetch this data
    """
    session = KeystoneSession(
        auth=KeystonePassword(
            auth_url=auth_url,
            username="novaobserver",
            password=observer_pass,
            project_name=project,
            user_domain_name="default",
            project_domain_name="default",
        )
    )

    ips = []
    for region in regions:
        try:
            client = novaclient.Client("2.0", session=session, region_name=region)
            for instance in client.servers.list():
                for value in instance.addresses.values():
                    for ip in value:
                        if is_valid_ipv4(ip["addr"]):
                            ips.append(str(ip["addr"]))

        except Unauthorized:
            logging.error(
                "Failed to get server list for project %s."
                "  Maybe the project was deleted." % project
            )
            raise

    return ips


# Check a given fqdn to see if it refers to the current host.
# This is complicated because the fqdn will almost certainly refer
# to a service name that points to a service IP that is not
# our primary IP.
def fqdn_is_us(fqdn):
    ip_for_fqdn = socket.gethostbyname(fqdn)
    for ifaceName in interfaces():
        addresses = [
            i["addr"]
            for i in ifaddresses(ifaceName).setdefault(
                AF_INET, [{"addr": "No IP addr"}]
            )
        ]
        if ip_for_fqdn in addresses:
            return True
    return False


def get_projects_with_nfs(mounts_config, observer_pass, auth_url):
    """
    Get populated project objects that need NFS exports
    :param mounts_config: dict
    :returns: list
    """
    projects = []

    # Special one-off session just to grab the list of regions
    session = KeystoneSession(
        auth=KeystonePassword(
            auth_url=auth_url,
            username="novaobserver",
            password=observer_pass,
            project_name="observer",
            user_domain_name="default",
            project_domain_name="default",
        )
    )
    keystoneclient = keystone_client.Client(session=session, interface="public")
    region_recs = keystoneclient.regions.list()
    regions = [region.id for region in region_recs]

    for projectname, config in mounts_config["private"].items():
        if "mounts" in config:
            mountpoints = []
            for mount, target in config["mounts"].items():
                if mount == "dumps":
                    # We can ignore this, dumps are handled in
                    # a totally different way.
                    pass
                elif ":" in target:
                    host = target.split(":")[0]
                    path = target.split(":")[1]
                    if fqdn_is_us(host):
                        mountpoints.append(path)
                else:
                    logging.warning(
                        "Found illformed mount entry for project %s" % projectname
                    )
                    # This and the following are legacy special cases;
                    #  once they move off of the metal labstore hosts
                    #  they can become generic cases with a :
                    mountpoints.append("/srv/tools/shared/tools")

            if len(mountpoints) == 0:
                # Skip project if it has no private mounts
                logging.debug("skipping exports for %s, no private mounts", projectname)
                continue
        else:
            continue
        ips = get_instance_ips(projectname, observer_pass, regions, auth_url)
        if ips:
            project = Project(projectname, config["gid"], ips, mountpoints)
            projects.append(project)
            logging.debug(
                "project %s has %s instances", projectname, len(project.instance_ips)
            )
        else:
            logging.warning("project %s has no instances; skipping.", projectname)

    # Validate that there are no duplicate gids
    gids = [p.gid for p in projects]
    if len(set(gids)) != len(gids):
        logging.error("duplicate GIDs found in project config, aborting")
        sys.exit(1)

    logging.warning("found %s projects requiring private mounts", len(projects))
    return projects


def exportfs():
    """ translate on disk definitions into active NFS exports
    :warn: this can fail with 0 exit code
    """
    exportfs = ["/usr/bin/sudo", "/usr/sbin/exportfs", "-ra"]

    logging.warning(" ".join(exportfs))
    subprocess.call(exportfs)


def write_public_exports(public_exports, exports_d_path):
    """ output public export definitions
    :param public_exports: dict of defined exports
    """
    public_paths = []
    for name, content in public_exports.items():
        logging.debug("writing exports file for public export %s", name)
        path = os.path.join(exports_d_path, "public_%s.exports" % name)
        with open(path, "w") as f:
            f.write(content)
        public_paths.append(path)

        # Make sure that the public mount is actually public
        make_public = ["/usr/bin/sudo", "/usr/bin/chmod", "1777", f"/srv/{name}"]
        logging.warning(" ".join(make_public))
        subprocess.call(make_public)
    logging.warning("found %s public NFS exports" % (len(public_paths)))
    return public_paths


def write_project_exports(mounts_config, exports_d_path, observer_pass, auth_url):
    """ output project export definitions
    :param mounts_config: dict of defined exports
    """
    project_paths = []
    projects = get_projects_with_nfs(mounts_config, observer_pass, auth_url)
    for project in projects:
        logging.debug("writing exports file for %s", project.name)
        path = os.path.join(exports_d_path, "%s.exports" % project.name)
        with open(path, "w") as f:
            f.write(project.get_exports())
        project_paths.append(path)
    return project_paths


def check_exports(no_exports_is_ok, project_paths, public_paths):
    """ check sanity of exports in this daemon iteration
    :param no_exports_is_ok: boolean, whether we expect to have no exports
    :param project_paths: list of project paths
    :param public_paths: list of public paths
    """
    if no_exports_is_ok:
        return True

    msg = "This could be an error somewhere, so doing nothing. Override with `--no-exports-is-ok'"

    if len(project_paths) == 0 and len(public_paths) == 0:
        logging.warning("nothing to export. {}".format(msg))
        return False

    return True


def do_fix_and_export(existing_wo_all):
    """ do the actual export and fix (delete) stale export files
    :param existing_wo_all: a list of paths with export files
    """

    if existing_wo_all:
        for unmanaged_export in existing_wo_all:
            # Catch potential exceptions here so we don't fail every export just
            #  because of one bad one
            try:
                with open(unmanaged_export) as f:
                    logging.warning(
                        "deleting %s with contents: %s", unmanaged_export, f.read()
                    )
                os.remove(unmanaged_export)
            except OSError:
                logging.exception("failed to delete export")

    exportfs()


def main():
    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        "--exports-d-path",
        default="/etc/exports.d/",
        help="Dir to write exports files to",
    )

    argparser.add_argument(
        "--config-path",
        default="/etc/nfs-mounts.yaml",
        help="Path to YAML file containing config of which exports to maintain",
    )

    argparser.add_argument(
        "--observer-pass",
        default="",
        help="Password for the OpenStack observer account",
    )

    argparser.add_argument(
        "--auth-url",
        default="",
        help="Keystone URL -- can be obtained from novaobserver.yaml",
    )

    argparser.add_argument(
        "--interval",
        type=int,
        default=0,
        help="Set interval to rerun at.  Default is 0 which means run once.",
    )

    argparser.add_argument("--debug", help="Turn on debug logging", action="store_true")

    argparser.add_argument(
        "--no-exports-is-ok",
        help="Having no NFS exports is OK. Otherwise, refuse to do anything if that happens",
        action="store_true",
    )

    args = argparser.parse_args()

    if not args.observer_pass:
        if os.path.isfile("/etc/novaobserver.yaml"):
            with open("/etc/novaobserver.yaml") as conf_fh:
                nova_observer_config = yaml.safe_load(conf_fh)

            args.observer_pass = nova_observer_config["OS_PASSWORD"]
            args.auth_url = nova_observer_config["OS_AUTH_URL"]
        else:
            argparser.error(
                "The --observer-pass argument is required without /etc/novaobserver.yaml"
            )

    if not args.auth_url:
        argparser.error(
            "The --auth-url argument is required without /etc/novaobserver.yaml"
        )

    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(message)s",
        level=logging.DEBUG if args.debug else logging.WARNING,
    )

    if os.getuid() == 0:
        logging.error("Daemon started as root, exiting")
        sys.exit(1)

    while True:

        try:
            with open(args.config_path) as f:
                config = yaml.safe_load(f)
        except Exception:
            logging.exception(
                "Could not load projects config file from %s", args.config_path
            )
            sys.exit(1)

        exports_d_path = args.exports_d_path

        existing_exports = [
            os.path.join(exports_d_path, filename)
            for filename in os.listdir(exports_d_path)
        ]

        if "public" not in config:
            # Putting an empty dict in here is easier than constantly checking
            #  to see if the key is defined.
            config["public"] = {}

        public_paths = write_public_exports(config["public"], exports_d_path)
        project_paths = write_project_exports(
            config, exports_d_path, args.observer_pass, args.auth_url
        )

        # compile list of entries in export_d path that are not defined in current config
        existing_wo_public = list(set(existing_exports) - set(public_paths))
        existing_wo_all = list(set(existing_wo_public) - set(project_paths))

        if check_exports(args.no_exports_is_ok, project_paths, public_paths):
            do_fix_and_export(existing_wo_all)

        if args.interval > 0:
            time.sleep(args.interval)
        else:
            break


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
