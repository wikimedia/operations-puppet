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
from django.utils.safestring import mark_safe

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
        # For some reason our parent class can't deal with these
        #  args, so extract them now if they're present
        if 'prefix' in kwargs:
            self.prefix = kwargs['prefix']
            self.name = self.prefix
            del kwargs['prefix']

        if 'tenant_id' in kwargs:
            self.tenant_id = kwargs['tenant_id']
            del kwargs['tenant_id']

        if hasattr(self, 'tenant_id') and hasattr(self, 'prefix'):
            self.slug += '-%s' % self.prefix
            self.tab_type = 'prefix'

        super(PuppetTab, self).__init__(*args, **kwargs)

        if 'instance' in self.tab_group.kwargs:
            self.tab_type = 'instance'
            tld = getattr(settings,
                          "INSTANCE_TLD",
                          "eqiad.wmflabs")
            self.instance = self.tab_group.kwargs['instance']

            self.prefix = "%s.%s.%s" % (self.instance.name,
                                        self.instance.tenant_id, tld)
            self.tenant_id = self.instance.tenant_id

        elif 'tenant_id' in self.tab_group.kwargs:
            self.tab_type = 'project'
            self.tenant_id = self.tab_group.kwargs['tenant_id']
            self.prefix = self.tab_group.kwargs['prefix']
        else:
            self.tab_type = 'prefix'

        self.add_caption()

        self.config = puppet_config(self.prefix, self.tenant_id)

    def add_caption(self):
        self.capption = ""
        if self.tab_type == 'prefix':
            self.caption = _("These puppet settings will affect all VMs in the"
                             " %s project whose names begin with \'%s\'.") % (
                self.tenant_id, self.prefix)

        elif self.tab_type == 'project':
            self.caption = _("These puppet settings will affect all VMs"
                             " in the %s project.") % self.tenant_id

        elif self.tab_type == 'instance':
            prefixes = puppet_config.get_prefixes(self.tenant_id)
            links = []
            for prefix in prefixes:
                if '.' in prefix:
                    continue
                if prefix == '_':
                    links.append("<a href=\"%s\">project config</a>" %
                                 urlresolvers.reverse(
                                     "horizon:project:puppet:index"))
                elif self.instance.name.startswith(prefix):
                    prefix_url = urlresolvers.reverse(
                        "horizon:project:prefixpuppet:index",
                        ) + "?tab=prefix_puppet__puppet-%s" % prefix
                    links.append("<a href=\"%s\">%s</a>" % (prefix_url,
                                                            prefix))

            if links:
                self.caption = mark_safe(_("This instance is also "
                                           "affected by the following puppet "
                                           "configs:  %s" % ", ".join(links)))

    def get_context_data(self, request, **kwargs):
        context = super(PuppetTab, self).get_context_data(request, **kwargs)
        context['prefix'] = self.prefix
        context['config'] = self.config
        context['prefix_tab'] = (self.tab_type == 'prefix')

        if hasattr(self, 'caption'):
            context['caption'] = self.caption
        elif 'caption' in self.tab_group.kwargs:
            context['caption'] = self.tab_group.kwargs['caption']

        kwargs = {
            'prefix': self.prefix,
            'tenantid': self.tenant_id,
        }
        context['edithieraurl'] = urlresolvers.reverse(
            "horizon:project:puppet:edithiera", kwargs=kwargs)
        context['editotherclassesurl'] = urlresolvers.reverse(
            "horizon:project:puppet:editotherclasses", kwargs=kwargs)

        url = "horizon:project:puppet:removepuppetprefix"
        context['removepuppetprefixurl'] = urlresolvers.reverse(url,
                                                                kwargs=kwargs)

        return context

    def get_puppet_data(self):
        return [role.update_prefix_data(self.prefix, self.tenant_id) for
                role in self.config.allroles]
