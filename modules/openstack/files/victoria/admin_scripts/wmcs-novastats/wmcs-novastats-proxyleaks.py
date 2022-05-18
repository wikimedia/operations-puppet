#!/usr/bin/python3
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
Dig through puppet configs, find and (sometimes) correct proxy records with
missing dns and dns records for missing proxies.
"""

import argparse

import requests

import mwopenstackclients
from designateclient.v2 import client as designateclientv2

clients = mwopenstackclients.clients()

PROXY_BACKEND_IP = "185.15.56.49"


def url_template():
    """Get the url template for accessing the proxy service."""
    keystone = clients.keystoneclient()
    proxy = keystone.services.list(type="proxy")[0]
    endpoint = keystone.endpoints.list(service=proxy.id, interface="public", enabled=True)[0]
    return endpoint.url


def proxy_client(project):
    proxy_url = url_template().replace("$(tenant_id)s", project)
    session = clients.session(project)
    return proxy_url, session


def all_mappings(project):
    """Return a list of proxies for a given project
    """
    proxy_url, session = proxy_client(project)
    resp = session.get(f"{proxy_url}/mapping", raise_exc=False)

    if resp.status_code == 400 and resp.text == "No such project":
        return []
    elif not resp:
        raise Exception("Proxy service request got status " + str(resp.status_code))
    else:
        return resp.json()["routes"]


def delete_mapping(project, domain):
    """Delete a single proxy
    """
    proxy_url, session = proxy_client(project)
    session.delete(f"{proxy_url}/mapping/{domain}")


def get_project_dns_zones(project_id):
    session = clients.session(project_id)
    client = designateclientv2.Client(session=session)
    zones = client.zones.list()
    return zones


def get_wmcloud_dns_recordsets(zone):
    session = clients.session("cloudinfra")
    client = designateclientv2.Client(session=session)
    return client.recordsets.list(zone["id"])


def get_wmflabs_dns_recordsets(zone):
    session = clients.session("wmflabsdotorg")
    client = designateclientv2.Client(session=session)
    return client.recordsets.list(zone["id"])


def get_project_dns_recordsets(project_id, zone):
    session = clients.session(project_id)
    client = designateclientv2.Client(session=session)
    domains = client.recordsets.list(zone["id"])
    return domains


def purge_leaks(delete=False):
    proxy_recordsets = {}
    proxyzones = get_project_dns_zones("wmflabsdotorg")
    for zone in proxyzones:
        if zone["name"] == "wmflabs.org.":
            for recordset in get_wmflabs_dns_recordsets(zone):
                if recordset["records"][0] == PROXY_BACKEND_IP:
                    proxy_recordsets[recordset["name"]] = recordset

    proxyzones = get_project_dns_zones("cloudinfra")
    for zone in proxyzones:
        if zone["name"] == "wmcloud.org.":
            for recordset in get_wmcloud_dns_recordsets(zone):
                if recordset["records"][0] == PROXY_BACKEND_IP:
                    proxy_recordsets[recordset["name"]] = recordset

    allinstances = clients.allinstances(allregions=True)
    all_nova_ips = []
    for instance in allinstances:
        for network in instance.addresses:
            all_nova_ips.append(instance.addresses[network][0]["addr"])

    for project in clients.allprojects():
        projectzones = get_project_dns_zones(project.id)
        project_recordsets = {}
        for zone in projectzones:
            for recordset in get_project_dns_recordsets(project.id, zone):
                if recordset["records"][0] == PROXY_BACKEND_IP:
                    project_recordsets[recordset["name"]] = recordset

        mappings = all_mappings(project.id)
        projectinstances = clients.allinstances(project.id, allregions=True)

        all_project_ips = []
        for instance in projectinstances:
            for network in instance.addresses:
                all_project_ips.append(instance.addresses[network][0]["addr"])

        for mapping in mappings:
            backend_ip = mapping["backends"][0].split(":")[1].strip("/")
            if backend_ip not in all_project_ips:
                if backend_ip not in all_nova_ips:
                    print("%s: possible stray proxy: %s" % (project.id, mapping))
                    if delete:
                        delete_mapping(project.id, mapping["domain"])
                else:
                    print("%s: proxy mapping outside of its project: %s" % (project.id, mapping))

            searchname = mapping["domain"]
            if not searchname.endswith("."):
                searchname += "."

            proxy_recordsets.pop(searchname, None)

    session = clients.session("wmflabsdotorg")
    dotorgclient = designateclientv2.Client(session=session)
    session = clients.session("cloudinfra")
    infraclient = designateclientv2.Client(session=session)
    for domain in proxy_recordsets:
        if domain == "wmflabs.org.":
            continue
        if domain == "*.wmflabs.org.":
            continue
        if domain == "wmcloud.org.":
            continue
        if domain == "*.wmcloud.org.":
            continue
        if domain == "proxy-eqiad1.wmflabs.org.":
            continue
        if domain == "proxy-eqiad1.wmcloud.org.":
            continue
        rset = proxy_recordsets[domain]
        print("found record unassociated with a proxy: %s" % rset)
        # Let's make sure there's really nothing there.
        url = "https://%s" % domain.rstrip(".")
        resp = requests.get(url, verify=False)
        print("%s: %s" % (resp.status_code, url))
        if resp.status_code != 502 and resp.status_code != 404:
            print(" ----   We found a weird one, at %s" % url)
        else:
            if delete:
                if "wmflabs" in domain:
                    dotorgclient.recordsets.delete(rset["zone_id"], rset["id"])
                if "wmcloud" in domain:
                    infraclient.recordsets.delete(rset["zone_id"], rset["id"])


parser = argparse.ArgumentParser(description="Find (and, optionally, remove) leaked proxy entries.")
parser.add_argument(
    "--delete", dest="delete", help="Actually delete leaked records", action="store_true"
)
args = parser.parse_args()

purge_leaks(args.delete)
