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
import json
import logging
import requests

from django.conf import settings
from django.core.cache import cache

logging.basicConfig()
LOG = logging.getLogger(__name__)


class PuppetClass():
    name = None
    docs = ""
    applied = False
    params = []
    param_values = []
    instance = None

    def update_instance(self, instance):
        self.instance = instance
        return self


def available_roles():
    key = 'wikimediapuppet_available_roles'
    roles = cache.get(key)
    if not roles:
        LOG.warn("Refreshing available puppet role cache.")
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
            obj = PuppetClass()
            obj.name = role['name']
            if 'doc' in role:
                obj.docs = role['doc']
            if 'parameters' in role:
                obj.params = role['parameters']
            obj.applied = False

            # Debug hack:
            if obj.name.endswith('statistics'):
                obj.applied = True

                #  Hack:  shorten this list for test/debug purposes
                roles.append(obj)
                break

            roles.append(obj)

        cache.set(key, roles, 300)

    return roles


def get_role_by_name(name):
    allRoles = available_roles()
    for role in allRoles:
        if role.name == name:
            return role
    return None
