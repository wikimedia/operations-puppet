#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""
makedomain is a tool for creating subdomains of existing designate domains.

Designate forbids creation of a subdomain when the superdomain already exists
as part of a different project.  It does, however, support cross-project
transfers of such domains.

So, this is a helper script which creates domains in the wmflabsdotorg project,
(or other arbitrary project) waits for them to become ACTIVE and then transfers
them.

Note that this only works with the keystone v2.0 API.

"""
import argparse

import openstack.config
import designatemakedomain

if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "wmcs-makedomain", description="Create a subdomain and transfer ownership"
    )

    argparser.add_argument(
        "--os-cloud", help="clouds.yaml section to use for auth", default="novaadmin"
    )

    argparser.add_argument(
        "--project", help="project for domain creation", required=True
    )
    argparser.add_argument("--domain", help="domain to create")
    argparser.add_argument(
        "--delete", action="store_true", help="delete domain rather than create"
    )
    argparser.add_argument(
        "--all",
        action="store_true",
        help="with --delete, delete all domains in a project",
    )
    argparser.add_argument(
        "--orig-project",
        help="the project that is oiginally owner of the superdomain in which "
        "the subdomain is being created. Typical values are either "
        "wmflabsdotorg or admin. Default: wmflabsdotorg",
        default="wmflabsdotorg",
    )

    args = argparser.parse_args()

    if args.delete and args.all:
        if args.domain:
            print(
                "--domain should not be specified unless if --delete and --all are true"
            )
            exit(1)
    else:
        if not args.domain:
            print("--domain must be specified unless you are doing --delete --all")
            exit(1)
        else:
            if not args.domain.endswith("."):
                args.domain = "%s." % args.domain

    auth = {}
    cloud_config = openstack.config.OpenStackConfig().get_all_clouds()
    for cloud in cloud_config:
        if cloud.name == args.os_cloud:
            auth["url"] = cloud.auth["auth_url"]
            auth["username"] = cloud.auth["username"]
            auth["password"] = cloud.auth["password"]
            auth["region"] = cloud.region_name

    if args.delete:
        designatemakedomain.deleteDomain(
            auth["url"],
            auth["username"],
            auth["password"],
            args.project,
            args.domain,
            auth["region"],
            args.all,
        )
    else:
        designatemakedomain.createDomain(
            auth["url"],
            auth["username"],
            auth["password"],
            args.project,
            args.domain,
            args.orig_project,
            region=auth["region"],
        )
