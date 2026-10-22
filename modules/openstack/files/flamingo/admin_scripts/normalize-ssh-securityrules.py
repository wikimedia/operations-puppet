#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

#
# Copyright 2021 Wikimedia Foundation
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
"""
Remove port 22 ingress rules from a project and then add
two new standardized ones.
"""

import argparse
import mwopenstackclients
import neutronclient.common.exceptions

if True:
    # eqiad1
    BASTION_DEFAULT_SECURITYGROUP_ID = "447f2b08-4b28-4355-885e-f1a083370a8e"
else:
    # codfw1dev
    BASTION_DEFAULT_SECURITYGROUP_ID = "badd3471-68d4-46ef-883a-37bc4b9609bc"


def print_rule(r):
    proto = r["protocol"] or "any"
    if r["port_range_min"] is None:
        ports = "all"
    elif r["port_range_min"] == r["port_range_max"]:
        ports = str(r["port_range_min"])
    else:
        ports = f"{r['port_range_min']}-{r['port_range_max']}"
    return f"{r['ethertype']} {proto} {ports} {r.get('remote_ip_prefix','no remote')}"


def normalize_ssh_rules(project, dry_run=False):
    clients = mwopenstackclients.clients(oscloud="novaadmin")
    group_name = "default"
    port = 22
    description = "Allow ssh only from VMs in the bastion project"

    client = clients.neutronclient(project=project)
    project_id = clients.project_id_for_name(project)

    existing_groups = client.list_security_groups()

    # double-check the project name  here because for some reason
    # we (sometimes?) get every group for every project
    group_dict_by_name = {
        g["name"]: g
        for g in existing_groups["security_groups"]
        if g["tenant_id"] == project
    }
    group_dict_by_id = {
        g["id"]: g
        for g in existing_groups["security_groups"]
        if g["tenant_id"] == project
    }

    if group_name not in group_dict_by_name:
        print(
            " ---  no security group named %s found for project %s"
            % (group_name, project)
        )
        return

    # scan for all port-22 rules in all groups and remove them
    rules_data = client.list_security_group_rules(tenant_id=project_id)
    rules = rules_data.get("security_group_rules", [])
    for rule in rules:
        group = group_dict_by_id.get(rule["security_group_id"])
        if group is None:
            continue
        if group["tenant_id"] != project:
            continue

        #  We're only normalizing ssh-specific rules, not rules
        #   that include ssh among other things.
        if not rule["port_range_min"] or not rule["port_range_max"]:
            continue
        if int(rule["port_range_min"]) < 22 or int(rule["port_range_max"]) > 22:
            continue
        if rule["direction"] != "ingress":
            continue

        proto = rule["protocol"] or "any"
        if proto.lower() != "tcp":
            continue

        # destroy the rule!
        print("Deleting a rule: %s" % print_rule(rule))
        if not dry_run:
            client.delete_security_group_rule(rule["id"])

    # Now add add an ssh rule for ipv6 and ipv4
    for version in ["4", "6"]:
        body = {
            "security_group_rule": {
                "security_group_id": group_dict_by_name[group_name]["id"],
                "direction": "ingress",
                "protocol": "tcp",
                "ethertype": f"ipv{version}",
                "port_range_max": port,
                "port_range_min": port,
                "description": description,
                "remote_group_id": BASTION_DEFAULT_SECURITYGROUP_ID,
            }
        }
        print("Creating rule in project %s: %s" % (project, body))
        if not dry_run:
            try:
                client.create_security_group_rule(body)
            except neutronclient.common.exceptions.Conflict as exc:
                print("Rule already exists")
                print(exc)


parser = argparse.ArgumentParser(
    description="""
Normalize ssh security group rules for a project by removing miscellaenous
port-22 rules and adding simple rules associated with the bastion project."""
)
parser.add_argument(
    "--dry-run",
    dest="dry_run",
    help="log without changing anything",
    action="store_true",
)
parser.add_argument("--project", help="project id or 'all'", required=True)

args = parser.parse_args()
normalize_ssh_rules(
    args.project,
    args.dry_run,
)
