#!/usr/bin/python
import json
import os
import sys
import yaml
import argparse
import itertools

from keystoneclient.auth.identity import generic
from keystoneauth1 import session as keystone_session

from keystoneclient.v3 import client as keystone_client

from novaclient import client as novaclient


def new_session(project):
    auth = generic.Password(
        auth_url=config['nova_api_url'],
        username=config['username'],
        password=config['password'],
        user_domain_name='Default',
        project_domain_name='Default',
        project_name=project)

    return keystone_session.Session(auth=auth)


argparser = argparse.ArgumentParser(
    description='Generate a lua script for public->private IP mappings')
argparser.add_argument(
    '--config-file',
    help='Path to config file',
    default='/etc/labs-dns-alias.yaml',
    type=argparse.FileType('r')
)
argparser.add_argument(
    '--check-changes-only',
    help='Exit 0 if there are no changes and 1 otherwise. Do not write to file',
    action='store_true'
)
args = argparser.parse_args()
config = yaml.safe_load(args.config_file)
session = new_session(config['observer_project_name'])
keystoneClient = keystone_client.Client(
    session=session, interface='public', connect_retries=5)

region_recs = keystoneClient.regions.list()
regions = [region.id for region in region_recs]

projects = []
for tenant in keystoneClient.projects.list():
    projects.append(tenant.name)

aliases = {}
for project in projects:
    # There's nothing useful in 'admin,' and
    #  the novaobserver isn't a member.
    if project == 'admin':
        continue

    project_session = new_session(project)
    for region in regions:
        client = novaclient.Client('2', session=project_session,
                                   connect_retries=5, region_name=region)

        for server in client.servers.list():
            for network_name, addresses in server.addresses.items():
                try:
                    private = [
                        str(ip['addr']) for ip in addresses
                        if ip['OS-EXT-IPS:type'] == 'fixed'
                    ]
                    public = [
                        str(ip['addr']) for ip in addresses
                        if ip['OS-EXT-IPS:type'] == 'floating'
                    ]
                    if public:
                        # Match all possible public IPs to all possible private ones
                        # Technically there can be more than one floating IP and more
                        # than one private IP Although this is never practically the
                        # case...
                        aliases[server.name] = list(itertools.product(public, private))
                except KeyError:
                    # This can happen if a server doesn't (yet) have any addresses,
                    # while it's being constructed.  In which case we simply
                    # harmlessly ignore it.
                    pass

output_d = {'aliasmapping': {}, 'extra_records': {}}
# Sort to prevent flapping around due to random ordering
for name in sorted(aliases.keys()):
    ips = aliases[name]
    for public, private in ips:
        output_d['aliasmapping'][public] = private

if 'extra_records' in config:
    extra_records = config['extra_records']

    for q in sorted(extra_records.keys()):
        output_d['extra_records'][q] = extra_records[q]

output = json.dumps(output_d)
if os.path.exists(config['output_path']):
    with open(config['output_path']) as f:
        current_contents = f.read()
else:
    current_contents = ""

exit_status = 0
if output != current_contents:
    if not args.check_changes_only:
        with open(config['output_path'], 'w') as f:
            f.write(output)
    exit_status = 1
if args.check_changes_only:
    sys.exit(exit_status)
