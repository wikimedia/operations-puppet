#!/usr/bin/python3
import json
import os
import sys
import yaml
import argparse

from keystoneauth1.identity.v3 import Password as KeystonePassword
from keystoneauth1 import session as keystone_session

from openstack import connection


def new_session(project, config):
    auth = KeystonePassword(
        auth_url=config["nova_api_url"],
        username=config["username"],
        password=config["password"],
        user_domain_name="Default",
        project_domain_name="Default",
        project_name=project,
    )

    return keystone_session.Session(auth=auth, connect_retries=3)


def main():
    argparser = argparse.ArgumentParser(
        description="Generate a lua script for public->private IP mappings"
    )
    argparser.add_argument(
        "--config-file",
        help="Path to config file",
        default="/etc/labs-dns-alias.yaml",
        type=argparse.FileType("r"),
    )
    argparser.add_argument(
        "--check-changes-only",
        help="Exit 0 if there are no changes and 1 otherwise. Do not write to file",
        action="store_true",
    )
    args = argparser.parse_args()
    config = yaml.safe_load(args.config_file)
    session = new_session(config["observer_project_name"], config)
    conn = connection.Connection(session=session)

    region_recs = conn.identity.regions()
    regions = [region.id for region in region_recs]

    projects = []
    for tenant in conn.identity.projects():
        # Avoid getting magnum created projects (different domain)
        if tenant.domain_id == "default":
            projects.append(tenant.name)

    # The output template
    output_d = {"aliasmapping": {}, "extra_records": {}}

    for project in projects:
        # There's nothing useful in 'admin,' and
        #  the novaobserver isn't a member.
        if project == "admin":
            continue

        project_session = new_session(project, config)
        for region in regions:
            r_conn = connection.Connection(
                "2", session=project_session, connect_retries=5, region_name=region
            )
            try:
                for floating_ip in r_conn.list_floating_ips():
                    if floating_ip.attached:
                        output_d["aliasmapping"][
                            floating_ip.floating_ip_address
                        ] = floating_ip.fixed_ip_address
            except Exception as error:
                raise Exception(
                    f"Unable to parse project={project}, region={region}, does the project exist?"
                ) from error

    if "extra_records" in config:
        output_d["extra_records"] = config["extra_records"]

    if os.path.exists(config["output_path"]):
        with open(config["output_path"]) as f:
            current_contents = json.load(f)
    else:
        current_contents = {}

    exit_status = 0
    if output_d != current_contents:
        if not args.check_changes_only:
            with open(config["output_path"], "w") as f:
                f.write(json.dumps(output_d))
        exit_status = 1
    if args.check_changes_only:
        return exit_status

    return 0


if __name__ == "__main__":
    sys.exit(main())
