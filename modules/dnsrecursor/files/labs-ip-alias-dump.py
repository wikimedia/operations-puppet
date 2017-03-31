#!/usr/bin/python
import os
import sys
import yaml
import argparse
import itertools

from keystoneclient.auth.identity import generic
from keystoneclient import session as keystone_session

from keystoneclient.v3 import client as keystone_client

from novaclient import client as novaclient


argparser = argparse.ArgumentParser()
argparser.add_argument(
    '--config-file',
    help='Path to config file',
    default='/etc/labs-dns-alias.yaml',
    type=argparse.FileType('r')
)
argparser.add_argument(
    '--check-changes-only',
    help='Exit with 0 if there are no changes and 1 if there are changes. Do not write to file',
    action='store_true'
)

LUA_LINE_TEMPLATE = '{table}["{key}"] = "{value}" -- {comment}\n'

args = argparser.parse_args()
config = yaml.safe_load(args.config_file)


def new_session(project):
    auth = generic.Password(
        auth_url=config['nova_api_url'],
        username=config['username'],
        password=config['password'],
        user_domain_name='Default',
        project_domain_name='Default',
        project_name=project)

    return keystone_session.Session(auth=auth)


session = new_session(config['observer_project_name'])

keystoneClient = keystone_client.Client(
    session=session, interface='public', connect_retries=5)

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
    client = novaclient.Client('2', session=project_session, connect_retries=5)

    for server in client.servers.list():
        serverAddresses = {}
        try:
            private = [
                str(ip['addr']) for ip in server.addresses['public']
                if ip['OS-EXT-IPS:type'] == 'fixed'
            ]
            public = [
                str(ip['addr']) for ip in server.addresses['public']
                if ip['OS-EXT-IPS:type'] == 'floating'
            ]
            if public:
                # Match all possible public IPs to all possible private ones
                # Technically there can be more than one floating IP and more than one private IP
                # Although this is never practically the case...
                aliases[server.name] = list(itertools.product(public, private))
        except KeyError:
            # This can happen if a server doesn't (yet) have any addresses, while it's being
            # constructed.  In which case we simply harmlessly ignore it.
            pass

output = 'aliasmapping = {}\n'
# Sort to prevent flapping around due to random ordering
for name in sorted(aliases.keys()):
    ips = aliases[name]
    for public, private in ips:
        output += LUA_LINE_TEMPLATE.format(
            table='aliasmapping',
            key=public,
            value=private,
            comment=name
        )

output += """
function postresolve (remoteip, domain, qtype, records, origrcode)
    for key,val in ipairs(records)
    do
        if (aliasmapping[val.content] and val.qtype == pdns.A) then
            val.content = aliasmapping[val.content]
            setvariable()
        end
    end
    return origrcode, records
end

"""

if 'extra_records' in config:
    output += 'extra_records = {}\n'
    extra_records = config['extra_records']

    for q in sorted(extra_records.keys()):
        output += LUA_LINE_TEMPLATE.format(
            table='extra_records',
            key=q,
            value=extra_records[q],
            comment=q
        )

    output += """
function preresolve(remoteip, domain, qtype)
    if extra_records[domain]
    then
        return 0, {
            {qtype=pdns.A, content=extra_records[domain], ttl=300, place="1"},
        }
    end
    return -1, {}
end
"""

if os.path.exists(config['output_path']):
    with open(config['output_path']) as f:
        current_contents = f.read()
else:
    current_contents = ""

if output == current_contents:
    # Do nothing!
    if args.check_changes_only:
        sys.exit(0)
else:
    if args.check_changes_only:
        sys.exit(1)
    with open(config['output_path'], 'w') as f:
        f.write(output)
