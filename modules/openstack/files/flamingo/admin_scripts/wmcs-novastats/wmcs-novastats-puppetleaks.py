#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

#
# Copyright 2017 Wikimedia Foundation
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
Dig through puppet configs, find and correct puppet definitions for missing instances.
"""

import argparse
import functools
import time

import mwopenstackclients


@functools.lru_cache
def get_url_template(clients, project) -> str:
    keystone = clients.keystoneclient(project)
    proxy = keystone.services.list(type="puppet-enc")[0]
    endpoint = keystone.endpoints.list(service=proxy.id, interface="public")[0]

    return endpoint.url


def get_enc_client(clients, project, base_url=False):
    session = clients.session(project)
    template = get_url_template(clients, project)

    if base_url:
        enc_api_url = template.replace("/$(project_id)s", "")
    else:
        enc_api_url = template.replace("$(project_id)s", project)

    return enc_api_url, session


def all_projects(clients):
    base_url, session = get_enc_client(clients, "admin", base_url=True)
    req = session.get(
        f"{base_url}/projects",
        headers={"Accept": "application/json"},
    )
    return req.json()["projects"]


def all_prefixes(clients, project):
    """Return a list of prefixes for a given project"""
    base_url, session = get_enc_client(clients, project)
    req = session.get(
        f"{base_url}/prefix",
        headers={"Accept": "application/json"},
    )
    return req.json()["prefixes"]


def delete_prefix(clients, project, prefix):
    """Return a list of prefixes for a given project"""
    base_url, session = get_enc_client(clients, project)
    print(f"Deleting prefix {prefix} in project {project}")
    session.delete(
        f"{base_url}/prefix/{prefix}",
        headers={"Accept": "application/json"},
    )

    time.sleep(1)


def delete_project(clients, project):
    """Deletes an entire project."""
    base_url, session = get_enc_client(clients, "admin", base_url=True)
    print(f"Deleting project {project}")
    session.delete(
        f"{base_url}/admin/project/{project}",
        headers={"Accept": "application/json"},
    )

    time.sleep(1)


def purge_duplicates(oscloud, delete=False):
    clients = mwopenstackclients.clients(oscloud=oscloud)

    keystone_projects = {project.id: project.name for project in clients.allprojects()}

    for project in all_projects(clients):
        if project not in keystone_projects:
            print(("Project %s has puppet prefixes but is not in keystone." % project))
            if delete:
                delete_project(clients, project)
            continue

        prefixes = all_prefixes(clients, project)
        instances = clients.allinstances(project, allregions=True)

        all_nova_instances = set()
        for instance in instances:
            # TODO: figure out the current domain instead of looping through them all?
            for deployment in ["eqiad1", "codfw1dev"]:
                all_nova_instances.add(
                    f"{instance.name.lower()}.{instance.tenant_id}."
                    f"{deployment}.wikimedia.cloud"
                )
                all_nova_instances.add(
                    f"{instance.name.lower()}.{keystone_projects[instance.tenant_id]}."
                    f"{deployment}.wikimedia.cloud"
                )

        for prefix in prefixes:
            if not prefix.endswith("wikimedia.cloud"):
                continue

            if prefix not in all_nova_instances:
                print(("stray prefix: %s" % prefix))
                if delete:
                    delete_prefix(clients, project, prefix)


parser = argparse.ArgumentParser(
    description="Find (and, optionally, remove) leaked Puppet ENC entries."
)
parser.add_argument(
    "--delete",
    dest="delete",
    help="Actually delete leaked entries",
    action="store_true",
)
parser.add_argument(
    "--os-cloud",
    help="clouds.yaml section to use for auth",
    default="novaadmin",
)
args = parser.parse_args()

purge_duplicates(args.os_cloud, args.delete)
