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
import puppet_roles
import yaml

from django.conf import settings
from django.core.cache import cache

logging.basicConfig()
LOG = logging.getLogger(__name__)

class puppet_config():
    def __init__(self, fqdn, tenant_id):
        self.fqdn = fqdn
        self.tenant_id = tenant_id
        self.apiurl = getattr(settings,
            "PUPPET_CONFIG_BACKEND",
            "http://labtestcontrol2001.wikimedia.org:8100/v1"
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
            self.roles = req.json()

        hieraurl = "%s/%s/prefix/%s/hiera" % (self.apiurl,
                                                   self.tenant_id,
                                                   self.fqdn)
        req = requests.get(hieraurl, verify=False)
        if req.status_code == 404:
            self.hiera = ""
        else:
            req.raise_for_status()
            self.hiera = yaml.load(json.dumps(req.json()['hiera']))

    def set_hiera(self, hiera_yaml):
        hiera_json = json.dumps(yaml.load(hiera_yaml), sort_keys=True, indent=2)
        hieraurl = "%s/%s/prefix/%s/hiera" % (self.apiurl,
                                                   self.tenant_id,
                                                   self.fqdn)
        req = requests.post(hieraurl, verify=False, data=hiera_json, headers={'Content-Type': 'application/json'})

    def set_role_list(self):
        pass
