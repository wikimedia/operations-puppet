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
Insert a security group rule into one or all projects
"""

import argparse
import mwopenstackclients
import neutronclient.common.exceptions


def backfill_rules(project, group_name, ip, port, description, dry_run=False):
    clients = mwopenstackclients.clients()
    if project == "all":
        projects = [proj.id for proj in clients.allprojects()]
    else:
        projects = [project]

    for project in projects:
        client = clients.neutronclient(project=project)

        existing_groups = client.list_security_groups()

        # double-check the project name  here because for some reason
        # we (sometimes?) get every group for every project
        group_dict = {
            g["name"]: g["id"]
            for g in existing_groups["security_groups"]
            if g["tenant_id"] == project
        }

        if group_name not in group_dict:
            print(
                " ---  no security group named %s found for project %s"
                % (group_name, project)
            )
            continue

        body = {
            "security_group_rule": {
                "security_group_id": group_dict[group_name],
                "direction": "ingress",
                "protocol": "tcp",
                "ethertype": "ipv4",
                "port_range_max": port,
                "port_range_min": port,
                "remote_ip_prefix": ip,
                "description": description,
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
    description="Add a security group rule to every project"
)
parser.add_argument(
    "--dry-run",
    dest="dry_run",
    help="log without changing anything",
    action="store_true",
)
parser.add_argument(
    "--group-name", help="security group name (not id) to modify", required=True
)
parser.add_argument("--remote-ip", help="ip or cidr to grant access to", required=True)
parser.add_argument("--dst-port", help="port to open", required=True)
parser.add_argument("--description", help="rule description", required=True)
parser.add_argument("--project", help="project id or 'all'", required=True)

args = parser.parse_args()
backfill_rules(
    args.project,
    args.group_name,
    args.remote_ip,
    args.dst_port,
    args.description,
    args.dry_run,
)
