#!/usr/bin/python

import sys

import cumin
import requests
import yaml

from cumin import query


NFS_MOUNT_FILE = '/etc/puppet/modules/labstore/files/nfs-mounts.yaml'


def get_projects_query():
    """Return the Cumin query with the list of projects that have NFS configured."""
    with open(NFS_MOUNT_FILE, 'r') as f:
        nfs_config = yaml.safe_load(f)
    projects = []
    for project in nfs_config['private']:
        projects.append('O{project:%s}' % project)
    return '({})'.format(' or '.join(projects))


def exclude_disabled_hosts(hosts):
    """Return the Cumin query with the list of hosts that have NFS disabled."""
    try:
        skipped_host_prefixes = []
        # Query to find hosts/host prefixes with NFS explicitly disabled through hiera
        resp = requests.get('https://tools.wmflabs.org/openstack-browser/api/hierakey/mount_nfs')
        for servers in resp.json()['servers'].values():
            for prefix, nfs_enabled in servers.iteritems():
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


def main(dest):
    """Generate a file with the list of matching hosts, one per line."""
    config = cumin.Config()
    cumin_query = get_projects_query()
    all_hosts = query.Query(config).execute(cumin_query)

    target_hosts = exclude_disabled_hosts(all_hosts)

    with open(dest, 'w') as f:
        f.write('\n'.join(target_hosts))


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit('Usage: {} TARGET_FILENAME'.format(sys.argv[0]))

    main(sys.argv[1])
