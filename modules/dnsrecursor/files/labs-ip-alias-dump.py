#!/usr/bin/python
import os
import sys
import yaml
import argparse
import itertools

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

aliases = {}
for project in config['projects']:
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
                str(ip['addr']) for ip in server.addresses['public'] if ip['OS-EXT-IPS:type'] == 'fixed'
            ]
            public = [
                str(ip['addr']) for ip in server.addresses['public'] if ip['OS-EXT-IPS:type'] == 'floating'
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

if 'cnames' in config:
    output += 'cnamemapping = {}\n'
    cnames = config['cnames']

    for cname in sorted(cnames.keys()):
        output += LUA_LINE_TEMPLATE.format(
            table='cnamemapping',
            key=cname,
            value=cnames[cname],
            comment=cname
        )

    output += """
function nxdomain(dq)
    print("Intercepting NXDOMAIN for: ",dq.qname:toString())
    if cnamemapping[dq.qname]
    then
        dq.rcode=0 -- make it a normal answer
        dq:addAnswer(pdns.CNAME, cnamemapping[dq.qname])
        return true
    end
    return false
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
