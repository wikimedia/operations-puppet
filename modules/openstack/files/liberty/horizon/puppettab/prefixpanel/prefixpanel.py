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


from collections import OrderedDict
from django.utils.translation import ugettext_lazy as _
import horizon
import logging

from horizon import tabs
from horizon.tabs import TabGroup

from wikimediapuppettab.tab import PuppetTab
from wikimediapuppettab.prefixpanel.plustab import PlusTab

logging.basicConfig()
LOG = logging.getLogger(__name__)


class PrefixPuppetPanel(horizon.Panel):
    name = _("Prefix Puppet")
    slug = "prefixpuppet"

    def handle(self, request, data):
        LOG.warning('PrefixPuppetPanel is handling')


class PrefixTabs(tabs.TabGroup):
    slug = "prefix_puppet"
    sticky = False

    def __init__(self, request, **kwargs):
        super(TabGroup, self).__init__()

        self.request = request
        self.kwargs = kwargs
        self._data = None
        tab_instances = []

        tenant_id = self.request.user.tenant_id

        # demo #1
        prefix = 'prefixone'
        tab_instances.append(("puppet-%s" % prefix,
                              PuppetTab(self,
                                        request,
                                        prefix=prefix,
                                        tenant_id=tenant_id)))
        # demo #2
        prefix = 'prefixtwo'
        tab_instances.append(("puppet-%s" % prefix,
                              PuppetTab(self,
                                        request,
                                        prefix=prefix,
                                        tenant_id=tenant_id)))
        # + tab
        tab_instances.append(('puppetprefixplus',
                              PlusTab(self, request, tenant_id=tenant_id)))

        self._tabs = OrderedDict(tab_instances)
        if self.sticky:
            self.attrs['data-sticky-tabs'] = 'sticky'
        if not self._set_active_tab():
            self.tabs_not_available()

    def handle(self, request, data):
        LOG.warning('PrefixTabs is handling')


class IndexView(tabs.TabbedTableView):
    tab_group_class = PrefixTabs
    template_name = 'project/puppet/prefix_panel.html'
    page_title = _("Prefix Puppet")

    def handle(self, request, data):
        LOG.warning('IndexView is handling')
