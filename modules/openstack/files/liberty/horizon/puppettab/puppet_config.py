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
    def __init__(self, prefix, tenant_id):
        self.prefix = prefix
        self.tenant_id = tenant_id
        self.apiurl = getattr(settings,
                              "PUPPET_CONFIG_BACKEND",
                              "http://labcontrol1001.wikimedia.org:8100/v1"
                              )
        self.refresh()

    def refresh(self):
        classesurl = "%s/%s/prefix/%s/roles" % (self.apiurl,
                                                self.tenant_id,
                                                self.prefix)
        req = requests.get(classesurl, verify=False)
        if req.status_code == 404:
            self.roles = []
        else:
            req.raise_for_status()
            self.roles = yaml.safe_load(req.text)['roles']

        hieraurl = "%s/%s/prefix/%s/hiera" % (self.apiurl,
                                              self.tenant_id,
                                              self.prefix)
        req = requests.get(hieraurl, verify=False)
        if req.status_code == 404:
            # Missing is the same as empty
            self.hiera_raw = "{}"
        else:
            req.raise_for_status()
            self.hiera_raw = yaml.safe_load(req.text)['hiera']

        hiera_yaml = yaml.safe_load(self.hiera_raw)
        if not hiera_yaml:
            hiera_yaml = {}
        self.role_dict = {}

        self.allroles = puppet_roles.available_roles()
        allrole_dict = {role.name: role for role in self.allroles}

        # other_classes is a list of roles that weren't enumerated by the puppet API.
        #  These could be roles from a locally hacked puppet repo, or roles that have been
        #  deleted from the puppet repo but still appear in the instance config.
        self.other_classes = []

        # Find the hiera lines that assign params to applied and known roles.
        #  these lines are removed from the hiera text and added as
        #  structured data to the role records instead.
        for role in list(self.roles):
            if role in allrole_dict:
                self.role_dict[role] = {}
                for key in hiera_yaml.keys():
                    if key.startswith(role):
                        # (len(role)+2) is the length of the rolename plus the ::,
                        # getting us the raw param name
                        argname = key[(len(role)+2):]
                        if hiera_yaml[key]:
                            self.role_dict[role][argname] = hiera_yaml[key]
                            del hiera_yaml[key]
                allrole_dict[role].mark_applied(self.role_dict[role])
            elif role:
                # This is an unknown role. Don't try to structure anything, just
                #  add the rolename to the list and let hiera take care of the
                #  params.
                self.other_classes.append(role)
                self.roles.remove(role)
            else:
                # Sometimes we get empty strings from crappy parsing
                self.roles.remove(role)

        self.other_classes_text = "\n".join(self.other_classes)

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
        if hiera_yaml:
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

    def set_roles(self, roles):
        list_dump = yaml.safe_dump(roles, default_flow_style=False)
        roleurl = "%s/%s/prefix/%s/roles" % (self.apiurl,
                                             self.tenant_id,
                                             self.prefix)
        req = requests.post(roleurl,
                            verify=False,
                            data=list_dump,
                            headers={'Content-Type': 'application/x-yaml'})
        req.raise_for_status()
        self.refresh()

    def set_other_class_list(self, other_class_list):
        self.set_roles(other_class_list + self.roles)

    def set_role_list(self, role_list):
        self.set_roles(role_list + self.other_classes)

    def set_hiera(self, hiera_yaml):
        if not hiera_yaml:
            # The user probably cleared the field.  That's fine, we'll just
            #  convert that to {}
            hiera_yaml = {}
        hiera_dump = yaml.safe_dump(hiera_yaml, default_flow_style=False)
        hieraurl = "%s/%s/prefix/%s/hiera" % (self.apiurl,
                                              self.tenant_id,
                                              self.prefix)
        req = requests.post(hieraurl,
                            verify=False,
                            data=hiera_dump,
                            headers={'Content-Type': 'application/x-yaml'})
        req.raise_for_status()
        self.refresh()

    @staticmethod
    def delete_prefix(tenant_id, prefix):
        apiurl = getattr(settings,
                         "PUPPET_CONFIG_BACKEND",
                         "http://labcontrol1001.wikimedia.org:8100/v1")
        prefixurl = "%s/%s/prefix/%s" % (apiurl, tenant_id, prefix)
        req = requests.delete(prefixurl, verify=False)
        req.raise_for_status()

    @staticmethod
    def get_prefixes(tenant_id):
        apiurl = getattr(settings,
                         "PUPPET_CONFIG_BACKEND",
                         "http://labcontrol1001.wikimedia.org:8100/v1")
        prefixurl = "%s/%s/prefix" % (apiurl, tenant_id)
        req = requests.get(prefixurl, verify=False)
        if req.status_code == 404:
            return []
        else:
            req.raise_for_status()
        return yaml.safe_load(req.text)['prefixes']
