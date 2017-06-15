#!/usr/bin/python
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
Dig through proxy configs, find and optionally delete proxies that
point to non-existent instances.
"""

import argparse
import mwopenstackclients

import requests

clients = mwopenstackclients.clients()


def proxy_endpoint():
    services = clients.keystoneclient().services.list()
    for service in services:
        if service.type == 'proxy':
            serviceid = service.id
            break
    endpoints = clients.keystoneclient().endpoints.list(serviceid)
    for endpoint in endpoints:
        if endpoint.interface == 'public':
            url = endpoint.url

    return url


def all_mappings(project):
    """Return a list of proxies for a given project
    """
    endpoint = proxy_endpoint()
    requrl = endpoint.replace("$(tenant_id)s", project)
    url = requrl + '/mapping'
    resp = requests.get(url, verify=False)
    if resp.status_code == 400 and resp.text == 'No such project':
        return []
    elif not resp:
        raise Exception("Proxy service request got status " +
                        str(resp.status_code))
    else:
        return resp.json()['routes']


def delete_mapping(projectid, domain):
    """Delete a single proxy
    """
    endpoint = proxy_endpoint()
    requrl = endpoint.replace("$(tenant_id)s", projectid)
    url = requrl + '/mapping/' + domain
    req = requests.delete(url, verify=False)
    req.raise_for_status()


def purge_leaks(delete=False):
    allinstances = clients.allinstances()
    all_nova_ips = [instance.addresses['public'][0]['addr'] for instance in allinstances]

    for project in clients.allprojects():
        mappings = all_mappings(project.id)
        projectinstances = clients.allinstances(project.id)

        all_project_ips = [instance.addresses['public'][0]['addr'] for instance in projectinstances]

        for mapping in mappings:
            backend_ip = mapping['backends'][0].split(":")[1].strip('/')
            if backend_ip == u'10.68.16.2':
                # Special case -- this is promethium, a bare-metal server
                continue
            if backend_ip not in all_project_ips:
                if backend_ip not in all_nova_ips:
                    print "%s: possible stray proxy: %s" % (project.id, mapping)
                    if delete:
                        delete_mapping(project.id, mapping['domain'])
                else:
                    print "%s: proxy mapping outside of its project: %s" % (project.id, mapping)


parser = argparse.ArgumentParser(
    description='Find (and, optionally, remove) leaked proxy entries.')
parser.add_argument('--delete',
                    dest='delete',
                    help='Actually delete leaked records',
                    action='store_true')
args = parser.parse_args()

purge_leaks(args.delete)
