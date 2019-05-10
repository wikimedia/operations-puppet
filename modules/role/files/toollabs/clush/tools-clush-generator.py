#!/usr/bin/python
"""
Simple script that generates a YAML file classifying all instances
on the tools project into groups based on the role they perform.

This YAML file can then be read by `tools-clush-interpreter` to
list instances within a group. This can be used by `clush` to
allow arbitrary command execution on targeted list of instances.

This is run in a cron every hour.
"""
import argparse

import yaml

from keystoneclient.auth.identity.v3 import Password as KeystonePassword
from keystoneclient.session import Session as KeystoneSession
from keystoneclient.v3 import client as keystone_client
from novaclient import client as novaclient


# Maps prefixes to hostgroup names
TOOLS_PREFIX_CLASSIFIER = {
    'webgrid-lighttpd-14': 'webgrid-lighttpd-trusty',
    'webgrid-generic': 'webgrid-generic',
    'webgrid-': 'webgrid',
    'exec-': 'exec',
    'exec-12': 'exec-precise',
    'exec-14': 'exec-trusty',
    'proxy-': 'webproxy',
    'checker-': 'checker',
    'redis-': 'redis',
    'services-': 'services',
    'bastion-': 'bastion',
    'cron-': 'cron',
    'grid-master': 'grid-master',
    'grid-shadow': 'grid-shadow',
    'mail': 'mail',
    'static-': 'static',
    'worker': 'k8s-worker',
    'k8s-master': 'k8s-master',
    'flannel-etcd': 'flannel-etcd',
    'k8s-etcd': 'k8s-etcd',
    'logs': 'logs',
    'precise-dev': 'precise-dev',
    'docker-builder': 'docker-builder',
    'prometheus': 'prometheus',
    'paws-master': 'paws-master',
    'paws-worker': 'paws-worker',
    '': 'all',
}


def get_regions(observer_pass):
    client = keystone_client.Client(session=KeystoneSession(auth=KeystonePassword(
        auth_url="http://cloudcontrol1003.wikimedia.org:5000/v3",
        username="novaobserver",
        password=observer_pass,
        project_name='observer',
        user_domain_name='default',
        project_domain_name='default'
    )), interface='public')

    return [region.id for region in client.regions.list()]


def get_hostgroups(classifier, observer_pass, regions):
    hostgroups = {name: [] for name in classifier.values()}

    for region in regions:
        client = novaclient.Client(
            "2.0",
            session=KeystoneSession(auth=KeystonePassword(
                auth_url="http://cloudcontrol1003.wikimedia.org:5000/v3",
                username="novaobserver",
                password=observer_pass,
                project_name='tools',
                user_domain_name='default',
                project_domain_name='default'
            )),
            region_name=region
        )
        for instance in client.servers.list():
            name = instance.name
            if name.startswith('tools-puppetmaster'):
                # To avoid chicken/egg strangeness, the tools puppetmaster
                #  is not itself managed by the tools puppetmaster.  That
                #  means clush keys aren't set up there.
                continue
            for prefix in classifier:
                if name.startswith('tools-' + prefix):
                    role = classifier[prefix]
                    hostgroups[role].append(name + ".tools.eqiad.wmflabs")

    return hostgroups


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'outputpath',
        help='Path to output hostgroup to host mappings'
    )
    parser.add_argument(
        '--observer-pass',
        required=True,
        help='Password for the OpenStack observer account'
    )
    args = parser.parse_args()

    regions = get_regions(args.observer_pass)
    hostgroups = get_hostgroups(TOOLS_PREFIX_CLASSIFIER, args.observer_pass, regions)
    with open(args.outputpath, 'w') as f:
        f.write(yaml.safe_dump(hostgroups, default_flow_style=False))


if __name__ == '__main__':
    main()
