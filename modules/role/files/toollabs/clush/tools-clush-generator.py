#!/usr/bin/python3


"""Simple generator script for clustershell to dynamically list all
   instances and classify them into groups based on their hostname.

"""


import argparse
import json
import urllib.request


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


def list_nodes(project_name, hostgroup):
    """List all nodes of a hostgroup on stdout."""
    prefix = '%s-%s' % (project_name, TOOLS_HOSTGROUPS[hostgroup])

    api_url = 'https://wikitech.wikimedia.org/w/api.php' \
              '?action=query&list=novainstances&niregion=eqiad&format=json' \
              '&niproject=' + project_name

    opener = urllib.request.build_opener()
    opener.addheaders = [('User-Agent', __file__)]
    data = json.loads(opener.open(api_url).read().decode('utf-8'))

    for instance in data['query']['novainstances']:
        name = instance['name']
        if name.startswith(prefix):
            print('%s.%s.eqiad.wmflabs' % (name, project_name))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='action')

    parser_map = subparsers.add_parser(
        'map',
        help='Print list of hosts in a hostgroup'
    )
    parser_map.add_argument(
        'group',
        help='Name of group whose instances should be printed'
    )

    parser_list = subparsers.add_parser(
        'list',
        help='List all hostgroups',
    )

    args = parser.parse_args()
    if args.action == 'list':
        list_hostgroups()
    elif args.action == 'map':
        with open('/etc/wmflabs-project', 'r') as f:
            project_name = f.read().rstrip('\n')

        list_nodes(project_name, args.group)
