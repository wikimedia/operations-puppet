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
Dig through puppet configs, find and correct puppet definitions for missing instances.
"""

import argparse
import mwopenstackclients

import requests
import yaml
import time

clients = mwopenstackclients.clients()


def url_template():
    return "http://labpuppetmaster1001.wikimedia.org:8101/v1/"


def all_prefixes(project):
    """Return a list of prefixes for a given project
    """
    url = url_template() + project + "/prefix"
    req = requests.get(url, verify=False)
    if req.status_code != 200:
        data = []
    else:
        data = yaml.safe_load(req.text)
    return data['prefixes']


def delete_prefix(project, prefix):
    """Return a list of prefixes for a given project
    """
    url = url_template() + project + "/prefix/" + prefix
    print("Deleting %s" % url)
    req = requests.delete(url, verify=False)
    req.raise_for_status()
    time.sleep(1)


def purge_duplicates(delete=False):
    for project in clients.allprojects():
        prefixes = all_prefixes(project.id)
        instances = clients.allinstances(project.id, allregions=True)

        all_nova_instances = ["%s.%s.eqiad.wmflabs" % (instance.name, instance.tenant_id)
                              for instance in instances]
        all_nova_shortname_instances = ["%s.eqiad.wmflabs" % (instance.name)
                                        for instance in instances]

        for prefix in prefixes:
            if not prefix.endswith('wmflabs'):
                continue
            if (prefix not in all_nova_instances and
                    prefix not in all_nova_shortname_instances):
                print "stray prefix: %s" % prefix
                if delete:
                    delete_prefix(project.id, prefix)


parser = argparse.ArgumentParser(
    description='Find (and, optionally, remove) leaked dns records.')
parser.add_argument('--delete',
                    dest='delete',
                    help='Actually delete leaked records',
                    action='store_true')
args = parser.parse_args()

purge_duplicates(args.delete)
