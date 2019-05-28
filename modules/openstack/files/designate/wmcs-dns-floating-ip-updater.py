#!/usr/bin/python
#
# Copyright (c) 2017 Wikimedia Foundation and contributors
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
import argparse
import ipaddress
import logging
import re
import yaml

import mwopenstackclients

logger = logging.getLogger(__name__)

PROJECT_ZONE_TEMPLATE = "{project}.wmflabs.org."
FQDN_TEMPLATE = "instance-{server}.{project}.wmflabs.org."
FQDN_REGEX = FQDN_TEMPLATE.replace('.', '\.').format(
    server='(.*)', project='{project}')
MANAGED_DESCRIPTION = "MANAGED BY dns-floating-ip-updater.py IN PUPPET - DO NOT UPDATE OR DELETE"


def managed_description_error(action, type, label):
    logger.warning(
        "Did not %s %s record for %s due to lack of managed_description!",
        action,
        type,
        label
    )


argparser = argparse.ArgumentParser(
    description='Update reverse DNS records for floating IPs')
argparser.add_argument(
    '-v', '--verbose', action='count', default=0, dest='loglevel',
    help='Increase logging verbosity')
argparser.add_argument(
    '--config-file',
    help='Path to config file',
    default='/etc/wmcs-dns-floating-ip-updater.yaml',
    type=argparse.FileType('r')
)
argparser.add_argument(
    '--envfile',
    help='Path to OpenStack authentication YAML file',
    default='/etc/novaadmin.yaml',
)
args = argparser.parse_args()

logging.basicConfig(
    level=max(logging.DEBUG, logging.WARNING - (10 * args.loglevel)),
    format='%(asctime)s %(name)-12s %(levelname)-8s: %(message)s',
    datefmt='%Y-%m-%dT%H:%M:%SZ'
)
logging.captureWarnings(True)
# Quiet some noisy 3rd-party loggers
logging.getLogger('requests').setLevel(logging.WARNING)
logging.getLogger('urllib3').setLevel(logging.WARNING)
logging.getLogger('iso8601.iso8601').setLevel(logging.WARNING)

config = yaml.safe_load(args.config_file)

floating_ip_ptr_fqdn_matching_regex = re.compile(
    config['floating_ip_ptr_fqdn_matching_regex'])

client = mwopenstackclients.Clients(envfile=args.envfile)

project_main_zone_ids = {}
public_addrs = {}
existing_As = []
# Go through every tenant
for tenant in client.keystoneclient().projects.list():
    logger.debug("Checking project %s", tenant.name)
    if tenant.name == 'admin':
        continue

    server_addresses = {}
    nova_client = client.novaclient(tenant.name)
    # Go through every instance
    for server in nova_client.servers.list():
        for network_name, addresses in server.addresses.items():
            public = [
                str(ip['addr']) for ip in addresses
                if ip['OS-EXT-IPS:type'] == 'floating'
            ]
            # If the instance has a public IP...
            if public:
                # Record their public IPs and generate their public name
                # according to FQDN_TEMPLATE. Technically there can be more
                # than one floating (and/or fixed) IP Although this is never
                # practically the case...
                server_addresses[server.name] = public
                A_FQDN = FQDN_TEMPLATE.format(
                    server=server.name, project=tenant.name)
                public_addrs[A_FQDN, tenant.name] = True, public
                logger.debug("Found public IP %s -> %s", public, A_FQDN)

    dns = mwopenstackclients.DnsManager(
        client, tenant=tenant.name)
    existing_match_regex = re.compile(FQDN_REGEX.format(project=tenant.name))
    # Now go through every zone the project controls
    for zone in dns.zones():
        logger.debug("Checking zone %s", zone['name'])
        # If this is their main zone, record the ID for later use
        if zone['name'] == PROJECT_ZONE_TEMPLATE.format(project=tenant.name):
            project_main_zone_ids[tenant.name] = zone['id']

        # Go through every recordset in the zone
        for recordset in dns.recordsets(zone['id']):
            logger.debug(
                "Found recordset %s %s", recordset['name'], recordset['type'])
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
                    if recordset['description'] == MANAGED_DESCRIPTION:
                        new_records = server_addresses[match.group(1)]
                        logger.info(
                            "Updating type A record for %s"
                            " - instance has different IPs - correct: %s"
                            " vs. current: %s",
                            recordset['name'],
                            str(new_records),
                            str(recordset['records']),
                        )
                        try:
                            dns.update_recordset(
                                zone['id'],
                                recordset['id'],
                                new_records,
                            )
                        except Exception:
                            logger.exception(
                                'Failed to update %s', recordset['name'])
                    else:
                        managed_description_error(
                            'update', 'A', recordset['name'])
                elif match.group(1) not in server_addresses:
                    # ... But instance does not actually exist. Delete!
                    if recordset['description'] == MANAGED_DESCRIPTION:
                        logger.info(
                            "Deleting type A record for %s "
                            " - instance does not exist",
                            recordset['name']
                        )
                        try:
                            dns.delete_recordset(
                                zone['id'], recordset['id'])
                        except Exception:
                            logger.exception(
                                'Failed to delete %s', recordset['name'])
                    else:
                        managed_description_error(
                            'delete', 'A', recordset['name'])
            elif '*' not in recordset['name']:
                # Recordset is not one of our FQDN_TEMPLATE ones, so just
                # store it so we can reflect its existence in PTR records
                # where appropriate.
                public_addrs[recordset['name'], tenant.name] = (
                    False, recordset['records'])

# Now we go through all the A record data we have stored
public_PTRs = {}
for (A_FQDN, project), (managed_here, IPs) in public_addrs.items():
    # Set up any that need to be and don't already exist
    if managed_here and A_FQDN not in existing_As:
        dns = mwopenstackclients.DnsManager(client, tenant=project)
        # Create instance-$instance.$project.wmflabs.org 120 IN A $IP
        # No IPv6 support in labs so no AAAAs
        logger.info("Creating A record for %s", A_FQDN)
        if project in project_main_zone_ids:
            try:
                dns.create_recordset(
                    project_main_zone_ids[project],
                    A_FQDN,
                    'A',
                    IPs,
                    description=MANAGED_DESCRIPTION
                )
            except Exception:
                logger.exception('Failed to create %s', A_FQDN)
        else:
            logger.warning("Oops! No main zone for project %s.", project)

    # Generate PTR record data, handling rewriting for RFC 2317 delegation as
    # configured
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
            logger.warning(
                "Not handling %s" +
                " because it doesn't end with %s",
                delegated_PTR_FQDN,
                config['floating_ip_ptr_zone']
            )

# Clean up reverse proxies. We don't want to generate PTR records for dozens
# or hundreds of hostnames that are sharing a single reverse proxy like
# project-proxy handles. If any IP has more than 10 reverse mappings then we
# will try to figure out a reasonable truncated list.
proxies = (k for k in public_PTRs if len(public_PTRs[k]) > 10)
proxy_fqdn_re = re.compile(FQDN_TEMPLATE.replace('.', '\.').format(
        server='(.*)', project='(.*)'))
for ptr in proxies:
    logger.info("Trimming FQDN list for %s", ptr)
    # Usually there will be an FQDN_TEMPLATE host in there somewhere
    fqdns = [h for h in public_PTRs[ptr] if proxy_fqdn_re.match(h)]
    if not fqdns:
        # If for some reason there are no FQDN_TEMPLATE hosts take the whole
        # giant list, but sorted just for fun
        fqdns = sorted(public_PTRs[ptr])
    # Only use the first 10 no matter how many ended up being found
    public_PTRs[ptr] = fqdns[:10]
    logger.debug("Trimmed FQDN list for %s is %s", ptr, public_PTRs[ptr])

# Set up designate client to write recordsets with
dns = mwopenstackclients.DnsManager(client, tenant='wmflabsdotorg')
# Find the correct zone ID for the floating IP zone
floating_ip_ptr_zone_id = None
for zone in dns.zones():
    if zone['name'] == config['floating_ip_ptr_zone']:
        floating_ip_ptr_zone_id = zone['id']
        break

# Zone should already exist!
assert floating_ip_ptr_zone_id is not None

existing_public_PTRs = {}
# Go through each record in the delegated PTR zone, deleting any with our
# managed_description that don't exist and updating any that don't match our
# public_PTRs data.
for recordset in dns.recordsets(floating_ip_ptr_zone_id):
    existing_public_PTRs[recordset['name']] = recordset
    if recordset['type'] == 'PTR':
        if recordset['name'] not in public_PTRs:
            if recordset['description'] == MANAGED_DESCRIPTION:
                # Delete whole recordset, it shouldn't exist anymore.
                logger.info("Deleting PTR record %s", recordset['name'])
                try:
                    dns.delete_recordset(
                        floating_ip_ptr_zone_id,
                        recordset['id']
                    )
                except Exception:
                    logger.exception('Failed to delete %s', recordset['name'])
            else:
                managed_description_error(
                    'delete', 'PTR', recordset['name'])
            continue
        new_records = set(public_PTRs[recordset['name']])
        if new_records != set(recordset['records']):
            if recordset['description'] == MANAGED_DESCRIPTION:
                # Update the recordset to have the correct IPs
                logger.info("Updating PTR record %s", recordset['name'])
                try:
                    dns.update_recordset(
                        floating_ip_ptr_zone_id,
                        recordset['id'],
                        list(new_records),
                    )
                except Exception:
                    logger.exception('Failed to update %s', recordset['name'])
            else:
                managed_description_error(
                    'update', 'PTR', recordset['name'])

# Create PTRs in delegated PTR zone
for delegated_PTR_FQDN, records in public_PTRs.items():
    # We already dealt with updating existing PTRs above.
    if delegated_PTR_FQDN not in existing_public_PTRs:
        logger.info(
            "Creating PTR record %s pointing to %s",
            delegated_PTR_FQDN,
            str(records)
        )
        try:
            dns.create_recordset(
                floating_ip_ptr_zone_id,
                delegated_PTR_FQDN,
                'PTR',
                records,
                description=MANAGED_DESCRIPTION
            )
        except Exception:
            logger.exception('Failed to create %s', delegated_PTR_FQDN)
