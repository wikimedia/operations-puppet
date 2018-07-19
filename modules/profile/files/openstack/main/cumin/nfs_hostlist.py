#!/usr/bin/python3

# Script that can be run from the labspuppetmaster that can generate a
# list of all hosts that have NFS enabled, filtered by share.
# It looks at the nfs-mounts.yaml config to find the list of projects and
# relevant shares mounted per project, and uses the cumin library (that is
# already configured to talk to the Openstack API) to query for the list of
# matching hosts. It then excludes any hosts that may explicitly have NFS
# disabled through the mount_nfs Hiera key - and this data is queried from the
# Openstack-browser tool's hierakey API endpoint.
#
# For usage, see : nfs-hostlist -h

import os
import sys

import argparse
import cumin
import requests
import yaml

from cumin import query


NFS_MOUNT_FILE = '/etc/puppet/modules/labstore/files/nfs-mounts.yaml'


def get_all_hosts(share):
    """
    Return the Cumin query with the list of projects that have NFS configured
    :param share: NFS Share to filter for
    :return String
    """
    config = cumin.Config()

    with open(NFS_MOUNT_FILE, 'r') as f:
        nfs_config = yaml.safe_load(f)

    projects = []

    for project, mounts in nfs_config['private'].items():
        if share == 'all' or share in mounts['mounts']:
            projects.append('O{project:%s}' % project)

    cumin_query = '({})'.format(' or '.join(projects))
    return query.Query(config).execute(cumin_query)


def exclude_disabled_hosts(hosts):
    """
    Look up the hosts that have NFS disabled explicitly through the mount_nfs
    hiera key, and exclude them from the list of all hosts
    :param hosts: List|Nodeset
    :return List|Nodeset
    """
    try:
        skipped_host_prefixes = []
        # Query to find hosts/host prefixes with NFS explicitly disabled through hiera
        resp = requests.get('https://tools.wmflabs.org/openstack-browser/api/hierakey/mount_nfs')
        for servers in resp.json()['servers'].values():
            for prefix, nfs_enabled in servers.items():
                if not nfs_enabled:
                    skipped_host_prefixes.append(prefix)

        # Find all hosts that match a hostname/host prefix in the list of NFS disabled hosts
        for skipped_host_prefix in skipped_host_prefixes:
            for host in hosts:
                if host.startswith(skipped_host_prefix):
                    hosts.remove(host)
    except Exception as e:
        sys.exit(e)

    return hosts


def write_hostlist(dest, share):
    """
    Generate a file with the list of matching hosts, one per line
    :param dest: Destination file path
    """

    all_hosts = get_all_hosts(share)
    target_hosts = exclude_disabled_hosts(all_hosts)

    if dest:
        with open(dest, 'w') as f:
            f.write('\n'.join(target_hosts))
    else:
        print('\n'.join(target_hosts))


if __name__ == '__main__':

    if os.geteuid() != 0:
        sys.exit("Script needs to be run as root")

    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        '--target_file',
        '-f',
        help='File path to write list of hosts| Optional: Defaults to stdout',
    )

    argparser.add_argument(
        '--nfs_share',
        '-s',
        help='Filter hosts by given NFS share',
        choices=['all', 'dumps', 'scratch', 'home', 'project',
                 'maps', 'tools-home', 'tools-project'],
        default='all',
    )

    args = argparser.parse_args()

    write_hostlist(args.target_file, args.nfs_share)
