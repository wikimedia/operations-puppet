#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
#
# Apply the specified security group to all VMs in the project.
#
# This will standardize ssh and cumin access for VMs that are not
# managed by puppet.
#
# Note that this presumes the security group already exists in the
# specified project.
import argparse
import logging

import mwopenstackclients

logger = logging.getLogger(__name__)


def update(os_cloud, project_id, security_group_name, dry_run):
    client = mwopenstackclients.Clients(oscloud=os_cloud)
    project_instances = client.allinstances(projectid=project_id)

    novaclient = client.novaclient(project=project_id)

    for instance in project_instances:
        if instance.status != 'ACTIVE':
            # This might not have security groups assigned yet.
            continue
        existing_groups = [group["name"] for group in instance.security_groups]
        if security_group_name not in existing_groups:
            logging.info(
                f"adding security group {security_group_name} to instance {instance.name}"
            )
            if not dry_run:
                novaclient.servers.add_security_group(instance.id, security_group_name)


def main():
    argparser = argparse.ArgumentParser(
        description="Add a security group to all servers in a project"
    )
    argparser.add_argument(
        "-v",
        "--dry-run",
        action="store_true",
        help=("Log what you will do without doing it."),
    )
    argparser.add_argument(
        "--os-cloud",
        help="clouds.yaml section to use for auth",
        default="novaadmin",
        required=True,
    )
    argparser.add_argument(
        "--project-id",
        help="ID of project to modify",
        default="novaadmin",
        required=True,
    )
    argparser.add_argument(
        "--security-group-name",
        help="security group to add to servers",
        default="novaadmin",
        required=True,
    )
    args = argparser.parse_args()

    update(
        args.os_cloud,
        args.project_id,
        args.security_group_name,
        args.dry_run,
    )
    exit(0)


if __name__ == "__main__":
    main()
