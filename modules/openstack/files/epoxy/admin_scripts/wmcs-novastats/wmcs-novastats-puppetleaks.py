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

clients = mwopenstackclients.clients()


@functools.lru_cache(maxsize=1)
def get_url_template() -> str:
    keystone = clients.keystoneclient()
    proxy = keystone.services.list(type="puppet-enc")[0]
    endpoint = keystone.endpoints.list(
        service=proxy.id, interface="public", enabled=True
    )[0]

    return endpoint.url


def get_enc_client(project, base_url=False):
    session = clients.session(project)

    if base_url:
        enc_api_url = get_url_template().replace("/$(project_id)s", "")
    else:
        enc_api_url = get_url_template().replace("$(project_id)s", project)

    return enc_api_url, session


def all_projects():
    base_url, session = get_enc_client("admin", base_url=True)
    req = session.get(
        f"{base_url}/projects",
        headers={"Accept": "application/json"},
    )
    return req.json()["projects"]


def all_prefixes(project):
    """Return a list of prefixes for a given project"""
    base_url, session = get_enc_client(project)
    req = session.get(
        f"{base_url}/prefix",
        headers={"Accept": "application/json"},
    )
    return req.json()["prefixes"]


def delete_prefix(project, prefix):
    """Return a list of prefixes for a given project"""
    base_url, session = get_enc_client(project)
    print(f"Deleting prefix {prefix} in project {project}")
    session.delete(
        f"{base_url}/prefix/{prefix}",
        headers={"Accept": "application/json"},
    )

    time.sleep(1)


def delete_project(project):
    """Deletes an entire project."""
    base_url, session = get_enc_client("admin", base_url=True)
    print(f"Deleting project {project}")
    session.delete(
        f"{base_url}/admin/project/{project}",
        headers={"Accept": "application/json"},
    )

    time.sleep(1)


def purge_duplicates(delete=False):
    keystone_projects = [project.id for project in clients.allprojects()]
    for project in all_projects():
        if project not in keystone_projects:
            print(("Project %s has puppet prefixes but is not in keystone." % project))
            if delete:
                delete_project(project)
            continue

        prefixes = all_prefixes(project)
        instances = clients.allinstances(project, allregions=True)

        all_nova_instances = []
        for instance in instances:
            # TODO: figure out the current domain instead of looping through them all?
            for deployment in ["eqiad1", "codfw1dev"]:
                all_nova_instances.append(
                    f"{instance.name.lower()}.{instance.tenant_id}."
                    f"{deployment}.wikimedia.cloud"
                )

        for prefix in prefixes:
            if not prefix.endswith("wikimedia.cloud"):
                continue

            if prefix not in all_nova_instances:
                print(("stray prefix: %s" % prefix))
                if delete:
                    delete_prefix(project, prefix)


parser = argparse.ArgumentParser(
    description="Find (and, optionally, remove) leaked Puppet ENC entries."
)
parser.add_argument(
    "--delete",
    dest="delete",
    help="Actually delete leaked entries",
    action="store_true",
)
args = parser.parse_args()

purge_duplicates(args.delete)
