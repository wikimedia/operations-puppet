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
import os

import designatemakedomain

if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "wmcs-makedomain", description="Create a subdomain and transfer ownership"
    )

    argparser.add_argument(
        "--designate-user",
        help="username for nova auth",
        default=os.environ.get("OS_USERNAME", None),
    )
    argparser.add_argument(
        "--designate-pass",
        help="password for nova auth",
        default=os.environ.get("OS_PASSWORD", None),
    )
    argparser.add_argument(
        "--keystone-url",
        help="url for keystone auth and catalog",
        default=os.environ.get("OS_AUTH_URL", None),
    )
    argparser.add_argument(
        "--region",
        help="keystone/designate region",
        default=os.environ.get("OS_REGION_NAME", None),
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

    if args.delete:
        designatemakedomain.deleteDomain(
            args.keystone_url,
            args.designate_user,
            args.designate_pass,
            args.project,
            args.domain,
            args.region,
            args.all,
        )
    else:
        designatemakedomain.createDomain(
            args.keystone_url,
            args.designate_user,
            args.designate_pass,
            args.project,
            args.domain,
            args.orig_project,
            region=args.region,
        )
