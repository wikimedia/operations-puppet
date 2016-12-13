#!/usr/bin/python3


"""Simple generator script for clustershell to dynamically list all
   instances and classify them into groups based on their hostname.
"""


import argparse

from keystoneclient.auth.identity.v3 import Password as KeystonePassword
from keystoneclient.session import Session as KeystoneSession
from novaclient import client as novaclient


# Maps hostgroup names to prefixes.
TOOLS_HOSTGROUPS = {
    'all': '',
    'bastion': 'bastion-',
    'checker': 'checker-',
    'cron': 'cron-',
    'docker-builder': 'docker-builder',
    'exec': 'exec-',
    'exec-precise': 'exec-12',
    'exec-trusty': 'exec-14',
    'flannel-etcd': 'flannel-etcd',
    'grid-master': 'grid-master',
    'grid-shadow': 'grid-shadow',
    'k8s-etcd': 'k8s-etcd',
    'k8s-master': 'k8s-master',
    'k8s-worker': 'worker',
    'logs': 'logs',
    'mail': 'mail',
    'precise-dev': 'precise-dev',
    'prometheus': 'prometheus',
    'redis': 'redis-',
    'services': 'services-',
    'static': 'static-',
    'webgrid': 'webgrid-',
    'webgrid-generic': 'webgrid-generic',
    'webgrid-lighttpd-precise': 'webgrid-lighttpd-12',
    'webgrid-lighttpd-trusty': 'webgrid-lighttpd-14',
    'webproxy': 'proxy-',
}


def list_hostgroups():
    """List all hostgroups on stdout."""
    for hostgroup in sorted(TOOLS_HOSTGROUPS):
        print(hostgroup)


def list_nodes(project_name, hostgroup, observer_pass):
    """List all nodes of a hostgroup on stdout."""
    client = novaclient.Client(
        '2.0',
        session=KeystoneSession(auth=KeystonePassword(
            auth_url='http://labcontrol1001.wikimedia.org:5000/v3',
            username='novaobserver',
            password=observer_pass,
            project_name=project_name,
            user_domain_name='default',
            project_domain_name='default'
        ))
    )

    prefix = '%s-%s' % (project_name, TOOLS_HOSTGROUPS[hostgroup])
    for instance in client.servers.list():
        name = instance.name
        if name.startswith(prefix):
            print('%s.%s.eqiad.wmflabs' % (name, project_name))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    subparsers = parser.add_subparsers(dest='action')
    subparsers.required = True

    parser_map = subparsers.add_parser(
        'map',
        help='Print list of hosts in a hostgroup'
    )
    parser_map.add_argument(
        '--observer-pass',
        help='Password for the OpenStack observer account',
        required=True
    )
    parser_map.add_argument(
        '--project',
        help='Name of project whose instances should be printed',
        required=True
    )
    parser_map.add_argument(
        'group',
        help='Name of group whose instances should be printed'
    )

    parser_list = subparsers.add_parser(
        'list',
        help='List all hostgroups'
    )

    args = parser.parse_args()
    if args.action == 'list':
        list_hostgroups()
    elif args.action == 'map':
        list_nodes(args.project, args.group, args.observer_pass)
