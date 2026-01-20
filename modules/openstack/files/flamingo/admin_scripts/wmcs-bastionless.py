#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0


import argparse
import mwopenstackclients

clients = mwopenstackclients.clients(oscloud="novaobserver")

keystone = clients.keystoneclient()

projects = clients.allprojects()

all_ids = [project.id for project in projects if project.domain_id == "default"]

projectnames = {project.id: project.name for project in projects}

roles = keystone.roles.list()
roledict = {role.name: role.id for role in roles}
bastionassignments = keystone.role_assignments.list(project="bastion")
bastionmembers = set(
    [
        assignment.user["id"]
        for assignment in bastionassignments
        if assignment.role["id"] == roledict["reader"]
    ]
)

# Select service users don't actually log in anywhere so don't need bastion access.
service_users = {"magnum", "wmflabsdotorgadmin", "novaobserver"}

PROMETHEUS_FILE = "/var/lib/prometheus/node.d/bastionlessusers.prom"

PROM_BLOB = (
    "# HELP cloudvps_bastionlessusers https://wikitech.wikimedia.org/wiki/Portal:"
    "Cloud_VPS/Admin/Runbooks/Users_not_in_bastion_project\n"
    "# TYPE cloudvps_bastionlessusers gauge\n"
    "cloudvps_bastionlessusers {users}\n"
)


def write_prom_file(count):
    with open(PROMETHEUS_FILE, "w") as f:
        f.write(PROM_BLOB.format(users=count))


def count_bastionless_users():
    count = 0
    for projectid in all_ids:
        if projectid in ["bastion", "tools"]:
            continue
        project = keystone.projects.get(projectid)
        assignments = keystone.role_assignments.list(project=projectid)
        readers = set(
            [
                assignment.user["id"]
                for assignment in assignments
                if assignment.role["id"] == roledict["reader"]
            ]
        )
        members = set(
            [
                assignment.user["id"]
                for assignment in assignments
                if assignment.role["id"] == roledict["member"]
            ]
        )

        unbastioned_readers = list(readers - bastionmembers - service_users)
        for user in unbastioned_readers:
            if user.endswith("manager") or user.endswith("admin"):
                unbastioned_readers.remove(user)
        if unbastioned_readers:
            print(
                "Project %s has unbastioned reader: %s"
                % (project.name, unbastioned_readers)
            )
            count += len(unbastioned_readers)

        unbastioned_members = list(members - bastionmembers - service_users)
        for user in unbastioned_members:
            if user.endswith("manager") or user.endswith("admin"):
                continue
            unbastioned_members.remove(user)
        if unbastioned_members:
            print(
                "Project %s has unbastioned member: %s"
                % (project.name, unbastioned_members)
            )
            count += len(set(unbastioned_members) - set(unbastioned_readers))
    return count


parser = argparse.ArgumentParser(
    description="Find users who belong to keystone projects but are not in the bastion project."
)
parser.add_argument(
    "--to-prometheus",
    help="Write stray record count to prometheus. Cannot be used with --delete",
    action="store_true",
)
args = parser.parse_args()
count = count_bastionless_users()

if args.to_prometheus:
    write_prom_file(count)
