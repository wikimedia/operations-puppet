#!/usr/bin/python

import sys

import cumin
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


def get_skipped_hosts_query():
    """Return the Cumin query with the list of hosts that have NFS disabled."""
    hosts = []
    query = ''
    if hosts:
        query = '(D{%s})' % ','.join(hosts)

    return query


def main(dest):
    """Generate a file with the list of matching hosts, one per line."""
    config = cumin.Config()
    cumin_query = get_projects_query()
    skip_hosts_query = get_skipped_hosts_query()
    if skip_hosts_query:
        cumin_query += 'and not {}'.format(skip_hosts_query)
    hosts = query.Query(config).execute(cumin_query)

    with open(dest, 'w') as f:
        f.write('\n'.join(hosts))


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit('Usage: {} TARGET_FILENAME'.format(sys.argv[0]))

    main(sys.argv[1])
