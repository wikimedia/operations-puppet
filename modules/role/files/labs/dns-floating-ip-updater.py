#!/usr/bin/python
import argparse
import re
import yaml

import keystoneclient.session as keystonesession
import keystoneclient.auth.identity.v2 as keystoneauth
import keystoneclient.client as keystoneclient
import novaclient.client as novaclient
import designateclient.v2.client as designateclient

PROJECT_ZONE_TEMPLATE = "{project}.wmflabs.org."
FQDN_TEMPLATE = "instance-{server}.{project}.wmflabs.org."
FQDN_REGEX = FQDN_TEMPLATE.replace('.', '\.').format(server='(.*)', project='{project}')
managed_description = "MANAGED BY dns-floating-ip-updater.py IN PUPPET - DO NOT UPDATE OR DELETE"

if True:
    # labs zone is 208.80.155.128/25, so we have delegation set up as suggested by RFC 2317
    orig_floating_ip_zone = "155.80.208.in-addr.arpa."
    floating_ip_zone = "128-25." + orig_floating_ip_zone
    matching_regex = re.compile(r"^(\d{1,3})\." + orig_floating_ip_zone.replace(".", "\."))
    replacement_pattern = "\\1." + floating_ip_zone
else:
    # Labtest
    floating_ip_zone = "17.196.10.in-addr.arpa."
    matching_regex = re.compile(r"^(.*)$")
    replacement_pattern = "\\1"

argparser = argparse.ArgumentParser()
argparser.add_argument(
    '--config-file',
    help='Path to config file',
    default='/etc/labs-floating-ips-dns-config.yaml',
    type=argparse.FileType('r')
)
args = argparser.parse_args()
config = yaml.safe_load(args.config_file)


def print_managed_description_error(action, type, label):
    print("Did not {action} {type} record for {label} due to lack of managed_description!".format(
        action=action,
        type=type,
        label=label
    ))


def getKeystoneSession(config, project):
    return keystonesession.Session(auth=keystoneauth.Password(
        auth_url=config['nova_api_url'],
        username=config['username'],
        password=config['password'],
        tenant_name=project
    ))

keystone_admin_session = getKeystoneSession(config, config['admin_project_name'])
keystone_client = keystoneclient.Client(
    session=keystone_admin_session,
    endpoint=config['nova_api_url']
)

keystone_sessions = {}
project_main_zone_ids = {}
public_addrs = {}
existing_As = []
for tenant in keystone_client.tenants.list():
    keystone_sessions[tenant.name] = getKeystoneSession(config, tenant.name)

    server_addresses = {}
    nova_client = novaclient.Client("2.0", session=keystone_sessions[tenant.name])
    for server in nova_client.servers.list():
        if server.addresses and 'public' in server.addresses:
            public = [
                str(ip['addr']) for ip in server.addresses['public']
                if ip['OS-EXT-IPS:type'] == 'floating'
            ]
            if public:
                # Technically there can be more than one floating IP and more than one private IP
                # Although this is never practically the case...
                server_addresses[server.name] = public
                A_FQDN = FQDN_TEMPLATE.format(server=server.name, project=tenant.name)
                public_addrs[A_FQDN, tenant.name] = True, public

    designate_client = designateclient.Client(session=keystone_sessions[tenant.name])
    existing_match_regex = re.compile(FQDN_REGEX.format(project=tenant.name))
    for zone in designate_client.zones.list():
        if zone['name'] == PROJECT_ZONE_TEMPLATE.format(project=tenant.name):
            project_main_zone_ids[tenant.name] = zone['id']

        for recordset in designate_client.recordsets.list(zone['id']):
            existing_As.append(recordset['name'])
            # No IPv6 support in labs so no AAAAs
            if recordset['type'] == 'A':
                match = existing_match_regex.match(recordset['name'])
                if match:
                    # Matches instances for this project, managed by this script
                    if match.group(1) not in server_addresses:
                        # ... But instance does not actually exist. Delete!
                        if recordset['description'] == managed_description:
                            print(
                                "Deleting type A record for " +
                                recordset['name'] +
                                " - instance does not exist"
                            )
                            designate_client.recordsets.delete(zone['id'], recordset['id'])
                        else:
                            print_managed_description_error('delete', 'A', recordset['name'])
                    elif recordset['records'] != server_addresses[match.group(1)]:
                        # ... But instance has a different set of IPs. Update!
                        new_records = set(server_addresses[match.group(1)])
                        if new_records != set(recordset['records']):
                            if recordset['description'] == managed_description:
                                # Update!
                                print(
                                    "Updating type A record for " +
                                    recordset['name'] +
                                    " - instance has different IPs: " +
                                    str(new_records) +
                                    " vs. " +
                                    str(recordset['records'])
                                )
                                recordset['records'] = list(new_records)
                                designate_client.recordsets.update(
                                    zone['id'],
                                    recordset['id'],
                                    recordset
                                )
                            else:
                                print_managed_description_error('update', 'A', recordset['name'])
                else:
                    public_addrs[recordset['name'], tenant.name] = False, recordset['records']

public_PTRs = {}
for (A_FQDN, project), (managed_here, IPv4s) in public_addrs.items():
    if managed_here and A_FQDN not in existing_As:
        designate_client = designateclient.Client(session=keystone_sessions[project])
        # Create instance-$instance.$project.wmflabs.org 120 IN A $IP
        # No IPv6 support in labs so no AAAAs
        print("Creating A record for " + A_FQDN)
        designate_client.recordsets.create(
            project_main_zone_ids[project],
            A_FQDN,
            'A',
            IPv4s,
            description=managed_description
        )

    for IPv4 in IPv4s:
        # Now deal with the reverse
        PTR_FQDN = '.'.join(reversed(IPv4.split('.'))) + '.in-addr.arpa.'
        delegated_PTR_FQDN = matching_regex.sub(replacement_pattern, PTR_FQDN)
        if delegated_PTR_FQDN.endswith(floating_ip_zone):
            if delegated_PTR_FQDN in public_PTRs:
                public_PTRs[delegated_PTR_FQDN].append(A_FQDN)
            else:
                public_PTRs[delegated_PTR_FQDN] = [A_FQDN]
        else:
            print(
                "Not handling " +
                delegated_PTR_FQDN +
                " because it doesn't end with " +
                floating_ip_zone
            )

# Set up designate client to write zones/recordsets with
wmflabsdotorg_designate_client = designateclient.Client(session=keystone_sessions['wmflabsdotorg'])
# Find the correct zone ID for the floating IP zone
floating_ip_zone_id = None
for zone in wmflabsdotorg_designate_client.zones.list():
    if zone['name'] == floating_ip_zone:
        floating_ip_zone_id = zone['id']
        break

assert floating_ip_zone_id is not None

existing_public_PTRs = {}
# Go through each record in the delegated PTR zone, deleting any with our managed_description
# that don't match our public_PTRs data.
for recordset in wmflabsdotorg_designate_client.recordsets.list(floating_ip_zone_id):
    existing_public_PTRs[recordset['name']] = recordset
    if recordset['type'] == 'PTR':
        if recordset['name'] not in public_PTRs:
            if recordset['description'] == managed_description:
                # Delete whole recordset
                print("Deleting PTR record " + recordset['name'])
                wmflabsdotorg_designate_client.recordsets.delete(
                    floating_ip_zone_id,
                    recordset['id']
                )
            else:
                print_managed_description_error('delete', 'PTR', recordset['name'])
            continue
        new_records = set(public_PTRs[recordset['name']])
        if new_records != set(recordset['records']):
            # Effectively, removes any records in the recordset that didn't
            # match our public_PTRs data
            if recordset['description'] == managed_description:
                # Update!
                recordset['records'] = list(new_records)
                print("Updating PTR record " + recordset['name'])
                wmflabsdotorg_designate_client.recordsets.update(
                    floating_ip_zone_id,
                    recordset['id'],
                    recordset
                )
            else:
                print_managed_description_error('update', 'PTR', recordset['name'])

# Create PTRs in delegated PTR zone
for delegated_PTR_FQDN, records in public_PTRs.items():
    if delegated_PTR_FQDN not in existing_public_PTRs:
        # Create!
        print("Creating PTR record " + delegated_PTR_FQDN)
        wmflabsdotorg_designate_client.recordsets.create(
            floating_ip_zone_id,
            delegated_PTR_FQDN,
            'PTR',
            records,
            description=managed_description
        )
