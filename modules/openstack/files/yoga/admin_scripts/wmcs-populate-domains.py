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
Create a new record in every single domain.  That causes designate to notify pdns about the
existence of said domains.

Without this, designate doesn't ever get around to informing pdns about these domains existing.
"""

import time

import requests
import yaml

import mwopenstackclients

clients = mwopenstackclients.clients()


def designate_endpoint_and_token():
    services = clients.keystoneclient().services.list()
    for service in services:
        if service.type == "dns":
            serviceid = service.id
            break
    endpoints = clients.keystoneclient().endpoints.list(serviceid)
    for endpoint in endpoints:
        if endpoint.interface == "public":
            url = endpoint.url

    session = clients.session()
    token = session.get_token()

    return (url, token)


def update_domains():
    (endpoint, token) = designate_endpoint_and_token()
    projects = clients.allprojects()
    i = 0
    for project in projects:
        headers = {"X-Auth-Token": token, "X-Auth-Sudo-Tenant-ID": project.id}
        req = requests.get("%s/v2/zones" % (endpoint), headers=headers, verify=False)
        req.raise_for_status()
        zones = yaml.safe_load(req.text)["zones"]
        print(project.id)
        designate = clients.designateclient(project.id)

        for zone in zones:
            print(zone["name"])
            try:
                i += 1
                designate.recordsets.create(
                    zone["id"], "dummyrecordforupdate", "A", ["192.168.0.1"]
                )
            except Exception as e:
                print(e)
                pass

    print("i is %s" % i)


def cleanup_dummyrecords():
    (endpoint, token) = designate_endpoint_and_token()
    projects = clients.allprojects()
    for project in projects:
        headers = {"X-Auth-Token": token, "X-Auth-Sudo-Tenant-ID": project.id}
        req = requests.get("%s/v2/zones" % (endpoint), headers=headers, verify=False)
        req.raise_for_status()
        zones = yaml.safe_load(req.text)["zones"]
        designate = clients.designateclient(project.id)

        for zone in zones:
            recordsets = designate.recordsets.list(zone["id"])
            for recordset in recordsets:
                if recordset["name"].split(".")[0] == "dummyrecordforupdate":
                    print(recordset)
                    designate.recordsets.delete(recordset["zone_id"], recordset["id"])


if __name__ == "__main__":
    update_domains()
    time.sleep(300)
    cleanup_dummyrecords()
