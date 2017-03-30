#!/usr/bin/python
import argparse
import ipaddress
import re
import yaml

from keystoneclient.auth.identity import generic
from keystoneclient import session as keystone_session
from keystoneclient.v3 import client as keystone_client
import novaclient.client as novaclient
import designateclient.v2.client as designateclient

PROJECT_ZONE_TEMPLATE = "{project}.wmflabs.org."
FQDN_TEMPLATE = "instance-{server}.{project}.wmflabs.org."
FQDN_REGEX = FQDN_TEMPLATE.replace('.', '\.').format(server='(.*)', project='{project}')
managed_description = "MANAGED BY dns-floating-ip-updater.py IN PUPPET - DO NOT UPDATE OR DELETE"

argparser = argparse.ArgumentParser()
argparser.add_argument(
    '--config-file',
    help='Path to config file',
    default='/etc/labs-floating-ips-dns-config.yaml',
    type=argparse.FileType('r')
)
args = argparser.parse_args()
config = yaml.safe_load(args.config_file)

floating_ip_ptr_fqdn_matching_regex = re.compile(config['floating_ip_ptr_fqdn_matching_regex'])


def print_managed_description_error(action, type, label):
    print("Did not {action} {type} record for {label} due to lack of managed_description!".format(
        action=action,
        type=type,
        label=label
    ))


def getKeystoneSession(config, project):
    auth = generic.Password(
        auth_url=config['nova_api_url'],
        username=config['username'],
        password=config['password'],
        user_domain_name='Default',
        project_domain_name='Default',
        project_name=project)

    return keystone_session.Session(auth=auth)


observer_session = getKeystoneSession(config, config['admin_project_name'])
keystone_client = keystone_client.Client(
                  session=observer_session, interface='public', connect_retries=5)

keystone_sessions = {}
project_main_zone_ids = {}
public_addrs = {}
existing_As = []
# Go through every tenant
for tenant in keystone_client.projects.list():
    keystone_sessions[tenant.name] = getKeystoneSession(config, tenant.name)

    server_addresses = {}
    nova_client = novaclient.Client("2.0", session=keystone_sessions[tenant.name])
    # Go through every instance
    for server in nova_client.servers.list():
        if server.addresses and 'public' in server.addresses:
            public = [
                str(ip['addr']) for ip in server.addresses['public']
                if ip['OS-EXT-IPS:type'] == 'floating'
            ]
            # If the instance has a public IP...
            if public:
                # Record their public IPs and generate their public name according to FQDN_TEMPLATE
                # Technically there can be more than one floating (and/or fixed) IP
                # Although this is never practically the case...
                server_addresses[server.name] = public
                A_FQDN = FQDN_TEMPLATE.format(server=server.name, project=tenant.name)
                public_addrs[A_FQDN, tenant.name] = True, public

    designate_client = designateclient.Client(session=keystone_sessions[tenant.name])
    existing_match_regex = re.compile(FQDN_REGEX.format(project=tenant.name))
    # Now go through every zone the project controls
    for zone in designate_client.zones.list():
        # If this is their main zone, record the ID for later use
        if zone['name'] == PROJECT_ZONE_TEMPLATE.format(project=tenant.name):
            project_main_zone_ids[tenant.name] = zone['id']

        # Go through every recordset in the zone
        for recordset in designate_client.recordsets.list(zone['id']):
            existing_As.append(recordset['name'])
            # No IPv6 support in labs so no AAAAs
            if recordset['type'] != 'A':
                continue

            match = existing_match_regex.match(recordset['name'])
            if match:
                # Matches instances for this project, managed by this script
                if (
                    match.group(1) in server_addresses and
                    set(recordset['records']) != set(server_addresses[match.group(1)])
                ):
                    # ... But instance has a different set of IPs. Update!
                    if recordset['description'] == managed_description:
                        new_records = server_addresses[match.group(1)]
                        print(
                            "Updating type A record for " +
                            recordset['name'] +
                            " - instance has different IPs - correct: " +
                            str(new_records) +
                            " vs. current: " +
                            str(recordset['records'])
                        )
                        recordset['records'] = new_records
                        del recordset['status'], recordset['action'], recordset['links']
                        designate_client.recordsets.update(
                            zone['id'],
                            recordset['id'],
                            recordset
                        )
                    else:
                        print_managed_description_error('update', 'A', recordset['name'])
                elif match.group(1) not in server_addresses:
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
            elif '*' not in recordset['name']:
                # Recordset is not one of our FQDN_TEMPLATE ones, so just store it so
                # we can reflect its existence in PTR records where appropriate.
                public_addrs[recordset['name'], tenant.name] = False, recordset['records']

# Now we go through all the A record data we have stored
public_PTRs = {}
for (A_FQDN, project), (managed_here, IPs) in public_addrs.items():
    # Set up any that need to be and don't already exist
    if managed_here and A_FQDN not in existing_As:
        designate_client = designateclient.Client(session=keystone_sessions[project])
        # Create instance-$instance.$project.wmflabs.org 120 IN A $IP
        # No IPv6 support in labs so no AAAAs
        print("Creating A record for " + A_FQDN)
        if project in project_main_zone_ids:
            designate_client.recordsets.create(
                project_main_zone_ids[project],
                A_FQDN,
                'A',
                IPs,
                description=managed_description
            )
        else:
            print("Oops! No main zone for that project.")

    # Generate PTR record data, handling rewriting for RFC 2317 delegation as configured
    for IP in IPs:
        PTR_FQDN = ipaddress.ip_address(IP.decode('ascii')).reverse_pointer + '.'
        delegated_PTR_FQDN = floating_ip_ptr_fqdn_matching_regex.sub(
            config['floating_ip_ptr_fqdn_replacement_pattern'],
            PTR_FQDN
        )
        if delegated_PTR_FQDN.endswith(config['floating_ip_ptr_zone']):
            if delegated_PTR_FQDN in public_PTRs:
                public_PTRs[delegated_PTR_FQDN].append(A_FQDN)
            else:
                public_PTRs[delegated_PTR_FQDN] = [A_FQDN]
        else:
            print(
                "Not handling " +
                delegated_PTR_FQDN +
                " because it doesn't end with " +
                config['floating_ip_ptr_zone']
            )

# Set up designate client to write recordsets with
wmflabsdotorg_designate_client = designateclient.Client(session=keystone_sessions['wmflabsdotorg'])
# Find the correct zone ID for the floating IP zone
floating_ip_ptr_zone_id = None
for zone in wmflabsdotorg_designate_client.zones.list():
    if zone['name'] == config['floating_ip_ptr_zone']:
        floating_ip_ptr_zone_id = zone['id']
        break

# Zone should already exist!
assert floating_ip_ptr_zone_id is not None

existing_public_PTRs = {}
# Go through each record in the delegated PTR zone, deleting any with our managed_description
# that don't exist and updating any that don't match our public_PTRs data.
for recordset in wmflabsdotorg_designate_client.recordsets.list(floating_ip_ptr_zone_id):
    existing_public_PTRs[recordset['name']] = recordset
    if recordset['type'] == 'PTR':
        if recordset['name'] not in public_PTRs:
            if recordset['description'] == managed_description:
                # Delete whole recordset, it shouldn't exist anymore.
                print("Deleting PTR record " + recordset['name'])
                wmflabsdotorg_designate_client.recordsets.delete(
                    floating_ip_ptr_zone_id,
                    recordset['id']
                )
            else:
                print_managed_description_error('delete', 'PTR', recordset['name'])
            continue
        new_records = set(public_PTRs[recordset['name']])
        if new_records != set(recordset['records']):
            if recordset['description'] == managed_description:
                # Update the recordset to have the correct IPs
                recordset['records'] = list(new_records)
                del recordset['status'], recordset['action'], recordset['links']
                print("Updating PTR record " + recordset['name'])
                wmflabsdotorg_designate_client.recordsets.update(
                    floating_ip_ptr_zone_id,
                    recordset['id'],
                    recordset
                )
            else:
                print_managed_description_error('update', 'PTR', recordset['name'])

# Create PTRs in delegated PTR zone
for delegated_PTR_FQDN, records in public_PTRs.items():
    # We already dealt with updating existing PTRs above.
    if delegated_PTR_FQDN not in existing_public_PTRs:
        print("Creating PTR record " + delegated_PTR_FQDN + " pointing to " + str(records))
        wmflabsdotorg_designate_client.recordsets.create(
            floating_ip_ptr_zone_id,
            delegated_PTR_FQDN,
            'PTR',
            records,
            description=managed_description
        )
