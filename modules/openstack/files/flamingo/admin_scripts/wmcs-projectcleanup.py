#!/usr/bin/env python3
# for ops/puppet CI: explicitly mark this file as python3 otherwise it defaults to py2

# SPDX-License-Identifier: Apache-2.0
# Copyright 2025 Andrew Bogott for the Wikimedia Foundation
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

# Because keystone doesnt have access to the project name after deletion,
# this is a helper script that can be run by hand (or by a cookbook) to clean
# up cruft leftover after project deletion.
#
# It will delete:
#
# - ldap group entries (e.g. cn=project-foo,ou=groups,dc=wikimedia,dc=org)
# - ldap sudo entries (e.g. cn=default-sudo,ou=sudoers,cn=foo,ou=projects,dc=wikimedia,dc=org)
# - ldap top-level project record (e.g. cn=foo,ou=projects,dc=wikimedia,dc=org)
# - wikitech project page (e.g. https://wikitech.wikimedia.org/wiki/Nova_Resource:Foo)
#
# It is safe to run this multiple times for the same project, but it will report errors
# when trying to delete ldap entries that don't exist.

import argparse
import logging
import mwopenstackclients

from keystone.common import rbac_enforcer
from keystone.common import provider_api
import keystone.server

from wmfkeystonehooks import ldapgroups
from wmfkeystonehooks import pageeditor

ENFORCER = rbac_enforcer.RBACEnforcer
PROVIDERS = provider_api.ProviderAPIs

CONF = keystone.conf.CONF
keystone.conf.configure()
keystone.conf.set_config_defaults()
CONF(
    project="keystone",
    version=None,
    default_config_files=["/etc/keystone/keystone.conf"],
    args={},
)

LOG = logging.getLogger("nova.%s" % __name__)


def cleanup_after_project_delete(project_name, skip_wiki_page=False):
    LOG.warning(
        "Beginning cleanup project deletion: %s",
        project_name,
    )

    ldapgroups.delete_ldap_project_group(project_name)

    if not skip_wiki_page:
        page_editor = pageeditor.PageEditor()
        page_editor.edit_page("", project_name, True)


if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "wmcs-projectcleanup",
        description="Delete ldap and wiki page remnants of a deleted project",
    )

    argparser.add_argument(
        "--project-name", help="Name (NOT ID) of project for cleanup", required=True
    )

    argparser.add_argument(
        "--skip-wiki-page",
        help="Do not clean up project-associated wiki page (useful in codfw1dev)",
        action="store_true",
    )

    args = argparser.parse_args()
    clients = mwopenstackclients.clients(oscloud="novaadmin")
    projectnames = [proj.name for proj in clients.allprojects()]
    if args.project_name in projectnames:
        print("A project named %s still exists in keystone" % args.project_name)
        print(
            "This script should only be run after a project has been deleted in keystone."
        )
        exit(1)

    cleanup_after_project_delete(args.project_name, args.skip_wiki_page)
