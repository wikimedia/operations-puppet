# Copyright (c) 2016 Andrew Bogott for Wikimedia Foundation
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

import logging
import requests

from django.conf import settings
from django.core.cache import cache

logging.basicConfig()
LOG = logging.getLogger(__name__)


# A single puppet class or role, used as the data type
#  for our Horizon table-of-roles UI
class PuppetClass():
    name = None
    docs = ""
    applied = False
    params = []
    raw_params = {}
    filter_tags = []
    instance = None

    def __init__(self, name):
        self.name = name
        self.docs = ""
        self.applied = False
        self.params = []
        self.raw_params = {}
        self.filter_tags = []
        self.instance = None

    def update_instance_data(self, instance):
        self.instance_id = instance.id
        self.tenant_id = instance.tenant_id
        tld = getattr(settings,
                      "INSTANCE_TLD",
                      "eqiad.wmflabs")
        self.fqdn = "%s.%s.%s" % (instance.name, instance.tenant_id, tld)
        return self

    def mark_applied(self, paramdict):
        self.applied = True
        self.params = paramdict
        return self


# Query the puppetmaster for a list of all available roles,
#  build a list of PuppetClass() objects out of those roles.
#
# This list should be fairly static and building it is
#  expensive, so it's cached in memcache.  Local copies
#  of this list will get altered with runtime data (e.g.
#  tenant and instance information) but the cached version
#  should remain useful universally.
def available_roles():
    key = 'wikimediapuppet_available_roles'
    roles = cache.get(key)
    if not roles:
        apiurl = getattr(settings,
                         "PUPPETMASTER_API",
                         "https://labtestcontrol2001.wikimedia.org:8140/puppet"
                         )
        roleurl = "%s/resource_types/role" % apiurl

        req = requests.get(roleurl, verify=False)
        req.raise_for_status()
        res = req.json()
        roles = []
        for role in res:
            if role['kind'] != 'class':
                continue
            obj = PuppetClass(role['name'])
            if 'doc' in role:
                obj.docs = role['doc']
            if 'parameters' in role:
                obj.params = role['parameters']
                obj.raw_params = role['parameters']

            if 'doc' in role and (role['doc'].find('filtertags') != -1):
                #  Collect filter tags from the role comment,
                #  and generate 'newdoc' which is the docs without
                #  the filter line.
                newdoc = ""
                for line in role['doc'].splitlines():
                    n = line.find('filtertags')
                    if n != -1:
                        obj.filter_tags = line[(n+11):].split()
                    else:
                        newdoc += "%s\n" % line
                obj.docs = newdoc

            if obj.name.startswith("role::labs::"):
                obj.filter_tags.append('labs')

            roles.append(obj)

        cache.set(key, roles, 300)

    return roles


def get_role_by_name(name):
    allRoles = available_roles()
    for role in allRoles:
        if role.name == name:
            return role
    return None
