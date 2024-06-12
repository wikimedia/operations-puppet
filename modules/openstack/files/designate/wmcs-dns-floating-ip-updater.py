#!/usr/bin/python3
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
import os
import argparse
import ipaddress
import logging
import re
import time
import yaml

import mwopenstackclients

logger = logging.getLogger(__name__)

FQDN_TEMPLATE = "instance-{server}.{zone}"
FQDN_REGEX = FQDN_TEMPLATE.replace(r".", r"\.").format(
    server="(.*)", zone="{zone}"
)
MANAGED_DESCRIPTION = (
    "MANAGED BY dns-floating-ip-updater.py IN PUPPET - DO NOT UPDATE OR DELETE"
)


def reverse_zone_name_for(network) -> str:
    if network.prefixlen < 24:
        raise ValueError(f"Unable to handle CIDR '{network}' longer than a /24")
    elif network.prefixlen == 24:
        return f"{network.network_address.reverse_pointer.removeprefix('0.')}."
    else:
        subnet_part = f"{network.network_address.packed[-1]}-{network.prefixlen}"
        supernet = reverse_zone_name_for(network.supernet(new_prefix=24))
        return f"{subnet_part}.{supernet}"


def find_floating_ip_zones(clients, reverse_zone_project):
    zones = {}
    designate_client = clients.designateclient(project=reverse_zone_project)

    for subnet in clients.neutronclient().list_subnets()["subnets"]:
        if "floating" not in subnet["name"]:
            continue

        # TODO: IPv6 support
        cidr = ipaddress.IPv4Network(subnet["cidr"])
        zone_name = reverse_zone_name_for(cidr)

        zone_data = designate_client.zones.list(criterion={"name": zone_name})
        if len(zone_data) != 1:
            logging.warning("Did not find reverse zone '%s' for subnet %s", zone_name, cidr)
            logging.warning("Please create it manually in the '%s' project!", reverse_zone_project)
            continue
        zones[cidr] = zone_data[0]

    return zones


def managed_description_error(action, type, label):
    logger.warning(
        "Did not %s %s record for %s due to lack of managed_description!",
        action,
        type,
        label,
    )


def update_tenant(
    client,
    tenant,
    project_zone_name,
    project_main_zone_ids,
    public_addrs,
    existing_As,
):
    logger.debug("Updating project %s (%s)", tenant.id, tenant.name)
    if tenant.name == "admin":
        return

    server_addresses = {}
    nova_client = client.novaclient(tenant.id)
    # Go through every instance
    for server in nova_client.servers.list():
        for network_name, addresses in server.addresses.items():
            public = [
                str(ip["addr"])
                for ip in addresses
                if ip["OS-EXT-IPS:type"] == "floating"
            ]
            # If the instance has a public IP...
            if public:
                # Record their public IPs and generate their public name
                # according to FQDN_TEMPLATE. Technically there can be more
                # than one floating (and/or fixed) IP Although this is never
                # practically the case...
                server_addresses[server.name] = public
                A_FQDN = FQDN_TEMPLATE.format(
                    server=server.name, zone=project_zone_name
                )
                public_addrs[A_FQDN, tenant.id] = True, public
                logger.debug("Found public IP %s -> %s", public, A_FQDN)

    dns = mwopenstackclients.DnsManager(client, tenant=tenant.id)
    existing_match_regex = re.compile(FQDN_REGEX.format(zone=project_zone_name))

    # Now go through every zone the project controls
    for zone in dns.zones():
        logger.debug("Checking zone %s", zone["name"])
        # If this is their main zone, record the ID for later use
        if zone["name"] == project_zone_name:
            project_main_zone_ids[tenant.id] = zone["id"]

        # Go through every recordset in the zone
        for recordset in dns.recordsets(zone["id"]):
            logger.debug(
                "Found recordset %s %s", recordset["name"], recordset["type"]
            )
            existing_As.append(recordset["name"])
            # No IPv6 support in labs so no AAAAs
            if recordset["type"] != "A":
                continue

            match = existing_match_regex.match(recordset["name"])
            if match:
                # Matches instances for this project, managed by this script
                if match.group(1) in server_addresses and set(
                    recordset["records"]
                ) != set(server_addresses[match.group(1)]):
                    # ... But instance has a different set of IPs. Update!
                    if recordset["description"] == MANAGED_DESCRIPTION:
                        new_records = server_addresses[match.group(1)]
                        logger.info(
                            "Updating type A record for %s"
                            " - instance has different IPs - correct: %s"
                            " vs. current: %s",
                            recordset["name"],
                            str(new_records),
                            str(recordset["records"]),
                        )
                        try:
                            dns.update_recordset(
                                zone["id"],
                                recordset["id"],
                                new_records,
                            )
                        except Exception:
                            logger.exception(
                                "Failed to update %s", recordset["name"]
                            )
                    else:
                        managed_description_error("update", "A", recordset["name"])
                elif match.group(1) not in server_addresses:
                    # ... But instance does not actually exist. Delete!
                    if recordset["description"] == MANAGED_DESCRIPTION:
                        logger.info(
                            "Deleting type A record for %s "
                            " - instance does not exist",
                            recordset["name"],
                        )
                        try:
                            dns.delete_recordset(zone["id"], recordset["id"])
                        except Exception:
                            logger.exception(
                                "Failed to delete %s", recordset["name"]
                            )
                    else:
                        managed_description_error("delete", "A", recordset["name"])
            elif "*" not in recordset["name"]:
                # Recordset is not one of our FQDN_TEMPLATE ones, so just
                # store it so we can reflect its existence in PTR records
                # where appropriate.
                public_addrs[recordset["name"], tenant.id] = (
                    False,
                    recordset["records"],
                )


def try_update_tenant(
    client,
    tenant,
    project_zone_name,
    project_main_zone_ids,
    public_addrs,
    existing_As,
    retries,
    retry_interval,
):
    retry = 0
    while retry <= retries:
        try:
            update_tenant(
                client=client,
                tenant=tenant,
                project_zone_name=project_zone_name,
                project_main_zone_ids=project_main_zone_ids,
                public_addrs=public_addrs,
                existing_As=existing_As
            )
            return
        except Exception:
            retry += 1
            logger.exception(
                "Failed to update tenant %s (%s), retrying %s out of %s"
                % (tenant.id, tenant.name, retry, retries)
            )
            if retry == retries:
                raise
            time.sleep(retry_interval)


def update(config, os_cloud, retries, retry_interval):
    client = mwopenstackclients.Clients(oscloud=os_cloud)

    reverse_zones = find_floating_ip_zones(client, config["reverse_zone_project"])

    project_main_zone_ids = {}
    public_addrs = {}
    existing_As = []
    # Go through every tenant
    for tenant in client.keystoneclient().projects.list():
        logger.info("Trying tenant %s", tenant.name)
        try_update_tenant(
            client=client,
            tenant=tenant,
            project_zone_name=config["project_zone_template"].format(project_id=tenant.id),
            project_main_zone_ids=project_main_zone_ids,
            public_addrs=public_addrs,
            existing_As=existing_As,
            retries=retries,
            retry_interval=retry_interval,
        )

    # Now we go through all the A record data we have stored
    public_PTRs = {}
    for (A_FQDN, project_id), (managed_here, IPs) in public_addrs.items():
        # Set up any that need to be and don't already exist
        if managed_here and A_FQDN not in existing_As:
            dns = mwopenstackclients.DnsManager(client, tenant=project_id)
            # Create instance-$instance.$project_id.wmcloud.org 120 IN A $IP
            # No IPv6 support yet so no AAAAs
            logger.info("Creating A record for %s", A_FQDN)
            if project_id in project_main_zone_ids:
                try:
                    dns.create_recordset(
                        project_main_zone_ids[project_id],
                        A_FQDN,
                        "A",
                        IPs,
                        description=MANAGED_DESCRIPTION,
                    )
                except Exception:
                    logger.exception("Failed to create %s", A_FQDN)
            else:
                logger.warning("Oops! No main zone for project %s.", project_id)

        # Generate PTR record data, handling rewriting for RFC 2317 delegation as
        # configured
        for IP in IPs:
            address = ipaddress.ip_address(IP)
            for subnet, zone in reverse_zones.items():
                if address not in subnet:
                    continue
                PTR_FQDN = f"{address.packed[-1]}.{zone['name']}"

                if PTR_FQDN in public_PTRs:
                    public_PTRs[PTR_FQDN].append(A_FQDN)
                else:
                    public_PTRs[PTR_FQDN] = [A_FQDN]

    # Clean up reverse proxies. We don't want to generate PTR records for dozens
    # or hundreds of hostnames that are sharing a single reverse proxy like
    # project-proxy handles. If any IP has more than 10 reverse mappings then we
    # will try to figure out a reasonable truncated list.
    proxies = (k for k in public_PTRs if len(public_PTRs[k]) > 10)
    proxy_fqdn_re = re.compile(
        FQDN_REGEX.format(
            zone=config["project_zone_template"].replace(r".", r"\.").format(project_id="(.*)")
        )
    )
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
    dns = mwopenstackclients.DnsManager(client, tenant=config["reverse_zone_project"])

    existing_public_PTRs = {}
    # Go through each record in the delegated PTR zone, deleting any with our
    # managed_description that don't exist and updating any that don't match our
    # public_PTRs data.
    for zone in reverse_zones.values():
        for recordset in dns.recordsets(zone["id"]):
            existing_public_PTRs[recordset["name"]] = recordset
            if recordset["type"] != "PTR":
                continue

            if recordset["name"] not in public_PTRs:
                if recordset["description"] == MANAGED_DESCRIPTION:
                    # Delete whole recordset, it shouldn't exist anymore.
                    logger.info("Deleting PTR record %s", recordset["name"])
                    try:
                        dns.delete_recordset(zone["id"], recordset["id"])
                    except Exception:
                        logger.exception("Failed to delete %s", recordset["name"])
                else:
                    managed_description_error("delete", "PTR", recordset["name"])
                continue
            new_records = set(public_PTRs[recordset["name"]])
            if new_records != set(recordset["records"]):
                if recordset["description"] == MANAGED_DESCRIPTION:
                    # Update the recordset to have the correct IPs
                    logger.info("Updating PTR record %s", recordset["name"])
                    try:
                        dns.update_recordset(
                            zone["id"],
                            recordset["id"],
                            list(new_records),
                        )
                    except Exception:
                        logger.exception("Failed to update %s", recordset["name"])
                else:
                    managed_description_error("update", "PTR", recordset["name"])

    # Create PTRs in delegated PTR zone
    for zone in reverse_zones.values():
        for delegated_PTR_FQDN, records in public_PTRs.items():
            if not delegated_PTR_FQDN.endswith(zone["name"]):
                continue

            # We already dealt with updating existing PTRs above.
            if delegated_PTR_FQDN in existing_public_PTRs:
                continue

            logger.info(
                "Creating PTR record %s pointing to %s",
                delegated_PTR_FQDN,
                str(records),
            )
            try:
                dns.create_recordset(
                    zone["id"],
                    delegated_PTR_FQDN,
                    "PTR",
                    records,
                    description=MANAGED_DESCRIPTION,
                )
            except Exception:
                logger.exception("Failed to create %s", delegated_PTR_FQDN)


def main():
    argparser = argparse.ArgumentParser(
        description="Update reverse DNS records for floating IPs"
    )
    argparser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        dest="loglevel",
        help=(
            "Increase logging verbosity, specify many times for more verbosity"
        ),
    )
    argparser.add_argument(
        "--config-file",
        help="Path to config file",
        default="/etc/wmcs-dns-floating-ip-updater.yaml",
        type=argparse.FileType("r"),
    )
    argparser.add_argument(
        "--os-cloud",
        help="clouds.yaml section to use for auth",
        default="novaadmin",
    )
    args = argparser.parse_args()

    logging.basicConfig(
        level=max(logging.DEBUG, logging.WARNING - (10 * args.loglevel)),
        format="%(asctime)s %(name)-12s %(levelname)-8s: %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%SZ",
    )
    logging.captureWarnings(True)
    # Quiet some noisy 3rd-party loggers
    logging.getLogger("requests").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("iso8601.iso8601").setLevel(logging.WARNING)

    if os.getuid() != 0:
        logging.critical("root required")
        exit(1)

    config = yaml.safe_load(args.config_file)
    retries = config.get("retries", 2)
    retry_interval = config.get("retry_interval", 120)

    retry = 0
    while retry <= retries:
        try:
            update(
                config,
                args.os_cloud,
                retries=retries,
                retry_interval=retry_interval,
            )
            exit(0)
        except Exception:
            retry += 1
            logger.exception(
                "Failed to update, retrying %s out of %s" % (retry, retries)
            )
            time.sleep(retry_interval)

    exit(1)


if __name__ == "__main__":
    main()
