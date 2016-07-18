#!/usr/bin/python
import os
import sys
import yaml
import argparse
import itertools

from keystoneclient.session import Session as KeystoneSession
from keystoneclient.auth.identity.v2 import Password as KeystonePassword
from keystoneclient.client import Client as KeystoneClient

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
LUA_LINE_TEMPLATE_PUBLIC_AS = '{table}["{key}"] = {value}\n'
LUA_LINE_TEMPLATE_PUBLIC_PTRS = '{table}["{key}"] = "{value}"\n'
FQDN_TEMPLATE = "instance-{server}.{project}.wmflabs.org."

args = argparser.parse_args()
config = yaml.safe_load(args.config_file)

auth = KeystonePassword(
    auth_url=config['nova_api_url'],
    username=config['username'],
    password=config['password'],
    tenant_name=config['admin_project_name']
)
keystoneClient = KeystoneClient(
    session=KeystoneSession(auth=auth), endpoint=config['nova_api_url'])

projects = []
for tenant in keystoneClient.tenants.list():
    projects.append(tenant.name)

aliases = {}
public_addrs = {}
for project in projects:
    client = novaclient.Client(
        "1.1",
        config['username'],
        config['password'],
        project,
        config['nova_api_url']
    )

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
                fqdn = FQDN_TEMPLATE.format(server=server.name, project=project)
                public_addrs[fqdn] = public
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

output += 'public_As = {}\npublic_PTRs = {}\n'
# Sort to prevent flapping around due to random ordering
for A_FQDN in sorted(public_addrs.keys()):
    IPv4s = public_addrs[A_FQDN]
    output += LUA_LINE_TEMPLATE_PUBLIC_AS.format(
        table='public_As',
        key=A_FQDN,
        value="{'" + "', '".join(IPv4s) + "'}"
    )

    for IPv4 in IPv4s:
        # Assuming dotted-quad notation is probably fine
        PTR_FQDN = '.'.join(reversed(IPv4.split('.'))) + '.in-addr.arpa.'
        output += LUA_LINE_TEMPLATE_PUBLIC_PTRS.format(
            table='public_PTRs',
            key=PTR_FQDN,
            value=A_FQDN
        )

output += """
function nxdomain(remoteip, domain, qtype)
    if qtype == pdns.A and public_As[domain] then
        ret = {}
        for i, IP in ipairs(public_As[domain]) do
            ret[i] = {qtype=pdns.A, content=IP, ttl=300}
        end
        return 0, ret
    end
    if qtype == pdns.PTR and public_PTRs[domain] then
        return 0, {{qtype=pdns.PTR, content=(public_PTRs[domain]), ttl=300}}
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
