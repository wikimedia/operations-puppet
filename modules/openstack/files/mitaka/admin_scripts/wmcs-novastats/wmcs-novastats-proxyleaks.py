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
Dig through puppet configs, find and (sometimes) correct proxy records with
missing dns and dns records for missing proxies.
"""

import argparse
import mwopenstackclients
from designateclient.v2 import client as designateclientv2

import requests

clients = mwopenstackclients.clients()

PROXY_BACKEND_IP = u'185.15.56.49'


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


def get_proxy_dns_zones():
    session = clients.session('wmflabsdotorg')
    client = designateclientv2.Client(session=session)
    zones = client.zones.list()
    return zones


def get_project_dns_zones(project_id):
    session = clients.session(project_id)
    client = designateclientv2.Client(session=session)
    zones = client.zones.list()
    return zones


def get_proxy_dns_recordsets(zone):
    session = clients.session('wmflabsdotorg')
    client = designateclientv2.Client(session=session)
    domains = client.recordsets.list(zone['id'])
    return domains


def get_project_dns_recordsets(project_id, zone):
    session = clients.session(project_id)
    client = designateclientv2.Client(session=session)
    domains = client.recordsets.list(zone['id'])
    return domains


def purge_leaks(delete=False):
    proxyzones = get_proxy_dns_zones()
    proxy_recordsets = {}
    for zone in proxyzones:
        if zone['name'] == 'wmflabs.org.':
            for recordset in get_proxy_dns_recordsets(zone):
                if recordset['records'][0] == PROXY_BACKEND_IP:
                    proxy_recordsets[recordset['name']] = recordset

    allinstances = clients.allinstances(allregions=True)
    all_nova_ips = []
    for instance in allinstances:
        for network in instance.addresses:
            all_nova_ips.append(instance.addresses[network][0]['addr'])

    for project in clients.allprojects():
        projectzones = get_project_dns_zones(project.id)
        project_recordsets = {}
        for zone in projectzones:
            for recordset in get_project_dns_recordsets(project.id, zone):
                if recordset['records'][0] == PROXY_BACKEND_IP:
                    project_recordsets[recordset['name']] = recordset

        mappings = all_mappings(project.id)
        projectinstances = clients.allinstances(project.id, allregions=True)

        all_project_ips = []
        for instance in projectinstances:
            for network in instance.addresses:
                all_project_ips.append(instance.addresses[network][0]['addr'])

        for mapping in mappings:
            backend_ip = mapping['backends'][0].split(":")[1].strip('/')
            if backend_ip not in all_project_ips:
                if backend_ip not in all_nova_ips:
                    print "%s: possible stray proxy: %s" % (project.id, mapping)
                    if delete:
                        delete_mapping(project.id, mapping['domain'])
                else:
                    print "%s: proxy mapping outside of its project: %s" % (project.id, mapping)
            searchname = mapping['domain']
            if not searchname.endswith('.'):
                searchname += '.'
            if searchname.count('.') > 3:
                print "ignoring outlier %s" % searchname
                # These are old leftovers in a different domain, hard to deal with automatically
                continue
            if searchname not in proxy_recordsets and searchname not in project_recordsets:
                print "No dns recordset found for %s" % searchname
            else:
                proxy_recordsets.pop(searchname, None)

    session = clients.session('wmflabsdotorg')
    dotorgclient = designateclientv2.Client(session=session)
    for domain in proxy_recordsets:
        if domain == 'wmflabs.org.':
            continue
        if domain == 'proxy-eqiad.wmflabs.org.':
            continue
        if domain == 'proxy-eqiad1.wmflabs.org.':
            continue
        rset = proxy_recordsets[domain]
        print "found record unassociated with a proxy: %s" % rset
        # Let's make sure there's really nothing there.
        url = "https://%s" % domain.rstrip('.')
        resp = requests.get(url, verify=False)
        print "%s: %s" % (resp.status_code, url)
        if resp.status_code != 502 and resp.status_code != 404:
            print " ----   We found a weird one, at %s" % url
        else:
            if delete:
                dotorgclient.recordsets.delete(rset['zone_id'], rset['id'])


parser = argparse.ArgumentParser(
    description='Find (and, optionally, remove) leaked proxy entries.')
parser.add_argument('--delete',
                    dest='delete',
                    help='Actually delete leaked records',
                    action='store_true')
args = parser.parse_args()

purge_leaks(args.delete)
