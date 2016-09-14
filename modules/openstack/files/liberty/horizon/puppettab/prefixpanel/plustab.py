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

from django import template
from django.template.loader import render_to_string
from django.utils.translation import ugettext_lazy as _

from horizon import tabs

logging.basicConfig()
LOG = logging.getLogger(__name__)


class PlusTab(tabs.Tab):
    name = _("+")
    slug = "puppetprefixplus"
    template_name = "project/puppet/plus_tab.html"
    prefix_name = False

    def __init__(self, *args, **kwargs):
        if 'tenant_id' in kwargs:
            self.tenant_id = kwargs['tenant_id']
            del kwargs['tenant_id']

        super(PlusTab, self).__init__(*args, **kwargs)

    def render(self):
        LOG.warning("rendering, and logging is working")
        context = template.RequestContext(self.request)
        context['prefix_name'] = self.prefix_name
        return render_to_string(self.get_template_name(self.request),
                                self.data, context_instance=context)

    def post(self, request, *args, **kwargs):
        LOG.warning("We've got POST!")
        self.prefix_name = request.POST["prefix_name"]
