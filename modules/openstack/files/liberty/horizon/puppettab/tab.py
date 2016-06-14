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
import puppet_roles
from puppet_config import puppet_config

logging.basicConfig()
LOG = logging.getLogger(__name__)


class PuppetTab(tabs.TableTab):
    name = _("Puppet Configuration")
    slug = "puppet"
    table_classes = (p_tables.PuppetTable,)
    template_name = "project/puppet/_detail_puppet.html"
    preload = False

    def get_instance(self):
        return self.tab_group.kwargs['instance']

    def get_context_data(self, request, **kwargs):
        context = super(PuppetTab, self).get_context_data(request, **kwargs)
        instance = self.get_instance()
        context['instance'] = instance
        tld = getattr(settings,
                      "INSTANCE_TLD",
                      "eqiad.wmflabs")

        fqdn =  "%s.%s.%s" % (instance.name, instance.tenant_id, tld)
        context['config'] = puppet_config(fqdn, instance.tenant_id)

        url = "horizon:project:puppet:edithiera"
        kwargs = {
            'fqdn': fqdn,
            'tenantid': instance.tenant_id,
            'instanceid': instance.id,
        }
        context['edithieraurl'] = urlresolvers.reverse(url, kwargs=kwargs)

        return context

    def get_puppet_data(self):
        return [role.update_instance(self.get_instance().id) for
                role in puppet_roles.available_roles()]

    def post(self, context, **response_kwargs):
        LOG.warn("post: %s" % self.request.GET.get('format', 'html'))
