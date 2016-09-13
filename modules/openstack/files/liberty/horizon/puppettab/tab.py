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

from django.core import urlresolvers
from django.utils.translation import ugettext_lazy as _

from horizon import tabs
from django.conf import settings

import puppet_tables as p_tables
from puppet_config import puppet_config

logging.basicConfig()
LOG = logging.getLogger(__name__)


class PuppetTab(tabs.TableTab):
    name = _("Puppet Configuration")
    slug = "puppet"
    table_classes = (p_tables.PuppetTable,)
    template_name = "project/puppet/_detail_puppet.html"
    preload = False

    def __init__(self, *args, **kwargs):
        super(PuppetTab, self).__init__(*args, **kwargs)
        if 'instance' in self.tab_group.kwargs:
            tld = getattr(settings,
                          "INSTANCE_TLD",
                          "eqiad.wmflabs")
            instance = self.tab_group.kwargs['instance']
            self.prefix = "%s.%s.%s" % (instance.name,
                                        instance.tenant_id, tld)
            self.tenant_id = instance.tenant_id
        elif 'prefix' in self.tab_group.kwargs:
            self.prefix = self.tab_group.kwargs['prefix']
            self.tenant_id = self.tab_group.kwargs['tenant_id']
        else:
            LOG.error("prefix and tenant_id unset")

        self.config = puppet_config(self.prefix, self.tenant_id)

    def get_context_data(self, request, **kwargs):
        context = super(PuppetTab, self).get_context_data(request, **kwargs)
        context['prefix'] = self.prefix
        context['config'] = self.config

        if 'caption' in self.tab_group.kwargs:
            context['caption'] = self.tab_group.kwargs['caption']
        else:
            context['caption'] = ""

        url = "horizon:project:puppet:edithiera"
        kwargs = {
            'prefix': self.prefix,
            'tenantid': self.tenant_id,
        }
        context['edithieraurl'] = urlresolvers.reverse(url, kwargs=kwargs)

        return context

    def get_puppet_data(self):
        return [role.update_prefix_data(self.prefix, self.tenant_id) for
                role in self.config.allroles]
