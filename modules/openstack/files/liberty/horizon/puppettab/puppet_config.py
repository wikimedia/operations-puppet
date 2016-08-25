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
import puppet_roles
import yaml

from django.conf import settings

logging.basicConfig()
LOG = logging.getLogger(__name__)


# Get/set puppet config for a given instance.
#
# This class manages all communication with the home-made puppet REST backend
class puppet_config():
    def __init__(self, fqdn, tenant_id):
        self.fqdn = fqdn
        self.tenant_id = tenant_id
        self.apiurl = getattr(settings,
                              "PUPPET_CONFIG_BACKEND",
                              "http://labcontrol1001.wikimedia.org:8100/v1"
                              )
        self.refresh()

    def refresh(self):
        classesurl = "%s/%s/prefix/%s/roles" % (self.apiurl,
                                                self.tenant_id,
                                                self.fqdn)
        req = requests.get(classesurl, verify=False)
        if req.status_code == 404:
            self.roles = []
        else:
            req.raise_for_status()
            self.roles = yaml.safe_load(req.text)['roles']

        hieraurl = "%s/%s/prefix/%s/hiera" % (self.apiurl,
                                              self.tenant_id,
                                              self.fqdn)
        req = requests.get(hieraurl, verify=False)
        if req.status_code == 404:
            self.hiera_raw = ""
        else:
            req.raise_for_status()
            self.hiera_raw = yaml.safe_load(req.text)['hiera']

        hiera_yaml = yaml.safe_load(self.hiera_raw)
        self.role_dict = {}

        # Find the hiera lines that assign params to applied roles.
        #  these lines are removed from the hiera text and added as
        #  structured data to the role records instead.
        for role in self.roles:
            self.role_dict[role] = {}
            for key in hiera_yaml.keys():
                if key.startswith(role):
                    # (len(role)+2) is the length of the rolename plus the ::,
                    # getting us the raw param name
                    argname = key[(len(role)+2):]
                    if hiera_yaml[key]:
                        self.role_dict[role][argname] = hiera_yaml[key]
                        del hiera_yaml[key]

        self.allroles = puppet_roles.available_roles()
        for role in self.allroles:
            if role.name in self.role_dict.keys():
                role.mark_applied(self.role_dict[role.name])

        # Move the applied roles to the top for UI clarity
        self.allroles.sort(key=lambda x: x.applied, reverse=True)

        self.hiera = yaml.safe_dump(hiera_yaml, default_flow_style=False)

    def remove_role(self, role):
        if not self.roles:
            LOG.error("Internal role list is empty, cannot remove")
            # TODO throw an exception
            return False

        roles = self.roles

        # Remove this role from our role list
        roles.remove(role.name)

        # Remove all related role args from hiera
        hiera_yaml = yaml.safe_load(self.hiera_raw)
        for key in hiera_yaml.keys():
            if key.startswith("%s::" % role.name):
                del hiera_yaml[key]

        self.set_role_list(roles)
        self.set_hiera(hiera_yaml)

    def apply_role(self, role, params):
        if not self.roles:
            # this is the first role, so build a fresh list
            roles = [role.name]
        else:
            roles = list(self.roles)
            if role.name not in roles:
                roles.append(role.name)

        # Translate the structured params and values
        # into hiera yaml
        hiera = yaml.safe_load(self.hiera_raw)
        for param in params.keys():
            fullparam = "%s::%s" % (role.name, param)
            if fullparam in hiera:
                if params[param]:
                    hiera[fullparam] = params[param]
                else:
                    del hiera[fullparam]
            else:
                if params[param]:
                    hiera[fullparam] = params[param]

        self.set_role_list(roles)
        self.set_hiera(hiera)

    def set_role_list(self, role_list):
        list_dump = yaml.safe_dump(role_list, default_flow_style=False)
        roleurl = "%s/%s/prefix/%s/roles" % (self.apiurl,
                                             self.tenant_id,
                                             self.fqdn)
        requests.post(roleurl,
                      verify=False,
                      data=list_dump,
                      headers={'Content-Type': 'application/x-yaml'})
        self.refresh()

    def set_hiera(self, hiera_yaml):
        hiera_dump = yaml.safe_dump(hiera_yaml, default_flow_style=False)
        hieraurl = "%s/%s/prefix/%s/hiera" % (self.apiurl,
                                              self.tenant_id,
                                              self.fqdn)
        requests.post(hieraurl,
                      verify=False,
                      data=hiera_dump,
                      headers={'Content-Type': 'application/x-yaml'})
        self.refresh()
