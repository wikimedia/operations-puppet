#!/usr/bin/python3
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
import sys
import subprocess

import keystoneauth1
from keystoneclient.auth.identity.v3 import Password as KeystonePassword
from keystoneclient.session import Session as KeystoneSession
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
    EXPORTS_TEMPLATE = '/exp/project/{name} ' + \
        '-rw,nohide,fsid=00000000000000000-{gid}-0000000000' + \
        ',no_subtree_check,async,no_root_squash ' + \
        '{instance_ips}'

    def __init__(self, name, gid, instance_ips, volumes):
        self.name = name
        self.instance_ips = instance_ips
        self.volumes = volumes
        self.gid = gid
        self.path = os.path.join('/exp/project/', name)

    def get_exports(self):
        return Project.EXPORTS_TEMPLATE.format(
            name=self.name,
            gid=self.gid,
            instance_ips=' '.join(self.instance_ips)
        )


def get_instance_ips(project, observer_pass, regions):
    """
    Return a list of Instance internal IPs for a given project

    This uses the Nova API to fetch this data
    """
    session = KeystoneSession(auth=KeystonePassword(
        auth_url="http://cloudcontrol1004.wikimedia.org:5000/v3",
        username="novaobserver",
        password=observer_pass,
        project_name=project,
        user_domain_name='default',
        project_domain_name='default'
    ))

    ips = []
    for region in regions:
        try:
            client = novaclient.Client(
                "2.0",
                session=session,
                region_name=region,
            )
            for instance in client.servers.list():
                # Only provide internal IPs!
                if 'public' in instance.addresses:
                    # This is a nova-network instance
                    for ip in instance.addresses['public']:
                        if ip['OS-EXT-IPS:type'] == 'fixed' and is_valid_ipv4(ip['addr']):
                            ips.append(str(ip['addr']))
                else:
                    # This is probably a neutron instance.  Export all fixed
                    #  addresses (probably there's only one)
                    for value in instance.addresses.values():
                        for ip in value:
                            if ip['OS-EXT-IPS:type'] == 'fixed' and is_valid_ipv4(ip['addr']):
                                ips.append(str(ip['addr']))

        except keystoneauth1.exceptions.http.Unauthorized:
            logging.error("Failed to get server list for project %s."
                          "  Maybe the project was deleted." % project)
            ips = []

    return ips


def get_projects_with_nfs(mounts_config, observer_pass):
    """
    Get populated project objects that need NFS exports
    :param mounts_config: dict
    :returns: list
    """
    projects = []

    # Special one-off session just to grab the list of regions
    session = KeystoneSession(auth=KeystonePassword(
        auth_url="http://cloudcontrol1004.wikimedia.org:5000/v3",
        username="novaobserver",
        password=observer_pass,
        project_name='observer',
        user_domain_name='default',
        project_domain_name='default'
    ))
    keystoneclient = keystone_client.Client(session=session, interface='public')
    region_recs = keystoneclient.regions.list()
    regions = [region.id for region in region_recs]

    server_vols = mounts_config['volumes_served']
    for name, config in mounts_config['private'].items():
        if 'mounts' in config:
            mounts = [k for k, v in config['mounts'].items()
                      if k in server_vols and v]
            if len(mounts) == 0:
                # Skip project if it has no private mounts
                logging.debug('skipping exports for %s, no private mounts', name)
                continue
        else:
            continue
        ips = get_instance_ips(name, observer_pass, regions)
        if ips:
            project = Project(name, config['gid'], ips, mounts)
            projects.append(project)
            logging.debug('project %s has %s instances',
                          name, len(project.instance_ips))
        else:
            logging.warning('project %s has no instances; skipping.', name)

    # Validate that there are no duplicate gids
    gids = [p.gid for p in projects]
    if len(set(gids)) != len(gids):
        logging.error('duplicate GIDs found in project config, aborting')
        sys.exit(1)

    logging.warning("found %s projects requiring private mounts", len(projects))
    return projects


def exportfs():
    """ translate on disk definitions into active NFS exports
    :warn: this can fail with 0 exit code
    """
    exportfs = [
        '/usr/bin/sudo',
        '/usr/sbin/exportfs',
        '-ra'
    ]

    logging.warning(' '.join(exportfs))
    subprocess.check_call(exportfs)


def write_public_exports(public_exports, exports_d_path):
    """ output public export definitions
    :param public_exports: dict of defined exports
    """
    public_paths = []
    for name, content in public_exports.items():
        logging.debug('writing exports file for public export %s', name)
        path = os.path.join(exports_d_path, 'public_%s.exports' % name)
        with open(path, 'w') as f:
            f.write(content)
        public_paths.append(path)
    logging.warning("found %s public NFS exports" % (len(public_paths)))
    return public_paths


def write_project_exports(mounts_config, exports_d_path, observer_pass):
    """ output project export definitions
    :param mounts_config: dict of defined exports
    """
    project_paths = []
    projects = get_projects_with_nfs(mounts_config, observer_pass)
    for project in projects:
        logging.debug('writing exports file for %s', project.name)
        path = os.path.join(exports_d_path, '%s.exports' % project.name)
        with open(path, 'w') as f:
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

    if len(project_paths) == 0:
        logging.warning("no projects with NFS exports. {}".format(msg))
        return False

    if len(public_paths) == 0:
        logging.warning("no public NFS exports. {}".format(msg))
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
                    logging.warning('deleting %s with contents: %s', unmanaged_export, f.read())
                os.remove(unmanaged_export)
            except OSError:
                logging.exception("failed to delete export")

    exportfs()


def main():
    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        '--exports-d-path',
        default='/etc/exports.d/',
        help='Dir to write exports files to',
    )

    argparser.add_argument(
        '--config-path',
        default='/etc/nfs-mounts.yaml',
        help='Path to YAML file containing config of which exports to maintain',
    )

    argparser.add_argument(
        '--observer-pass',
        required=True,
        help='Password for the OpenStack observer account',
    )

    argparser.add_argument(
        '--interval',
        type=int,
        default=0,
        help='Set interval to rerun at.  Default is 0 which means run once.',
    )

    argparser.add_argument(
        '--debug',
        help='Turn on debug logging',
        action='store_true'
    )

    argparser.add_argument(
        '--no-exports-is-ok',
        help='Having no NFS exports is OK. Otherwise, refuse to do anything if that happens',
        action='store_true'
    )

    args = argparser.parse_args()

    logging.basicConfig(
        format='%(asctime)s %(levelname)s %(message)s',
        level=logging.DEBUG if args.debug else logging.WARNING)

    if os.getuid() == 0:
        logging.error('Daemon started as root, exiting')
        sys.exit(1)

    while True:

        try:
            with open(args.config_path) as f:
                config = yaml.safe_load(f)
        except Exception:
            logging.exception('Could not load projects config file from %s', args.config_path)
            sys.exit(1)

        exports_d_path = args.exports_d_path

        existing_exports = [
            os.path.join(exports_d_path, filename)
            for filename in os.listdir(exports_d_path)]

        public_paths = write_public_exports(config['public'], exports_d_path)
        project_paths = write_project_exports(config, exports_d_path, args.observer_pass)

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
