#!/usr/bin/python3
#
# Copyright (c) 2020 Wikimedia Foundation, Inc.
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

# Script that can be run from the cloud-cumin host that can generate a
# list of all hosts that have NFS enabled, filtered by share.
# It looks at the nfs-mounts.yaml config to find the list of projects and
# relevant shares mounted per project, and uses the cumin library (that is
# already configured to talk to the Openstack API) to query for the list of
# matching hosts. It then excludes any hosts that may explicitly have NFS
# disabled through the mount_nfs Hiera key - and this data is queried from the
# Openstack-browser tool's hierakey API endpoint.
#
# For usage, see : nfs-hostlist -h

import argparse
import os
import sys

import cumin
import requests
import yaml

from cumin import query


class NfsConfig:
    """This object an the interface with nfs-mounts.yaml
    """
    def __init__(self, yaml_path="/etc/nfs-mounts.yaml"):
        with open(yaml_path) as yaml_file:
            nfs_config = yaml.safe_load(yaml_file)

        self.config = nfs_config["private"]
        all_l = [list(y["mounts"].keys()) for y in self.config.values()]
        self.valid_mounts = set(
            [mount for mount_list in all_l for mount in mount_list]
        )
        self.valid_projects = set(self.config.keys())

    def filter_projects(self, mounts):
        return set(
            [
                x
                for x in self.valid_projects
                if any(mount in mounts for mount in self.config[x]["mounts"])
            ]
        )


def get_all_hosts(projects):
    """
    Return the Cumin query with the list of projects that have NFS configured
    :param projects: set of projects to gather hosts for
    :return String
    """
    config = cumin.Config()
    projects_q = ['O{{project:{}}}'.format(project) for project in projects]
    cumin_query = '({})'.format(' or '.join(projects_q))
    return query.Query(config).execute(cumin_query)


def exclude_disabled_hosts(hosts):
    """
    Look up the hosts that have NFS disabled explicitly through the mount_nfs
    hiera key, and exclude them from the list of all hosts
    :param hosts: List|Nodeset
    :return List|Nodeset
    """

    try:
        # Query to find hosts/host prefixes with NFS explicitly disabled through hiera
        resp = requests.get('https://openstack-browser.toolforge.org/api/hierakey/mount_nfs')
        skipped_host_prefixes = [
            pfx for svrs in resp.json()['servers'].values() for pfx, nfs in svrs.items() if not nfs]

        # Find all hosts that match a hostname/host prefix in the list of NFS disabled hosts
        scrub_hosts = set(
            [host for pfx in skipped_host_prefixes for host in hosts if host.startswith(pfx)]
            )
    except Exception as e:
        sys.exit(e)

    return set(hosts) - scrub_hosts


def write_hostlist(dest, projects):
    """
    Generate a file with the list of matching hosts, one per line
    :param dest: Destination file path
    """

    all_hosts = get_all_hosts(projects)
    target_hosts = exclude_disabled_hosts(all_hosts)

    if dest:
        with open(dest, 'w') as f:
            f.write('\n'.join(target_hosts))
    else:
        print('\n'.join(target_hosts))


def get_args():
    """
    parse command line arguments
    """
    arg_p = argparse.ArgumentParser()

    arg_p.add_argument(
        "-c",
        "--config",
        type=str,
        default="/etc/nfs-mounts.yaml",
        help="Location of the nfs-mounts.yaml file",
    )
    arg_p.add_argument(
        '--target_file',
        '-f',
        help='File path to write list of hosts| Optional: Defaults to stdout',
    )

    proj_group = arg_p.add_mutually_exclusive_group(required=True)
    proj_group.add_argument(
        "--all-projects",
        action="store_true",
        default=False,
        help="Run across all projects",
    )
    proj_group.add_argument(
        "-p",
        "--projects",
        nargs="+",
        type=str,
        help="Openstack project to run against",
    )

    mount_group = arg_p.add_mutually_exclusive_group(required=True)
    mount_group.add_argument(
        "--all-mounts",
        action="store_true",
        default=False,
        help="Run against any NFS-mounted host in selected projects",
    )
    mount_group.add_argument(
        "-m",
        "--mounts",
        type=str,
        nargs="+",
        help="Run for hosts with these particular mounts in selected projects",
    )

    return arg_p.parse_args()


def main():
    if os.geteuid() != 0:
        sys.exit("Script needs to be run as root")

    args = get_args()

    nfs_config = NfsConfig(args.config)
    mounts = set(args.mounts) if not args.all_mounts else nfs_config.valid_mounts
    if not nfs_config.valid_mounts.issuperset(mounts):
        print("Invalid mounts: {}".format(mounts))
        exit(1)

    projects = (
        set(args.projects) if not args.all_projects else nfs_config.valid_projects
    )
    if not nfs_config.valid_projects.issuperset(projects):
        print("Invalid projects: {}".format(projects))
        exit(1)

    # If mounts were specified, not projects, drop projects that
    # don't have those mounts
    if len(nfs_config.valid_mounts - mounts) > 0 and args.all_projects:
        projects = nfs_config.filter_projects(mounts)

    write_hostlist(args.target_file, projects)


if __name__ == '__main__':
    main()
