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
from wikimediapuppettab.puppet_config import puppet_config

logging.basicConfig()
LOG = logging.getLogger(__name__)


class PrefixPuppetPanel(horizon.Panel):
    name = _("Prefix Puppet")
    slug = "prefixpuppet"


class PrefixTabs(tabs.TabGroup):
    slug = "prefix_puppet"
    sticky = False

    def __init__(self, request, **kwargs):
        super(TabGroup, self).__init__()

        self.request = request
        self.kwargs = kwargs
        self._data = None
        self.request = request

        self.tenant_id = self.request.user.tenant_id
        self._tabs = OrderedDict(self.get_dynamic_tab_list())
        if self.sticky:
            self.attrs['data-sticky-tabs'] = 'sticky'
        if not self._set_active_tab():
            self.tabs_not_available()

    def get_dynamic_tab_list(self):
        prefixlist = puppet_config.get_prefixes(self.tenant_id)
        LOG.warning("prefixlist: %s" % prefixlist)

        tab_instances = []
        # One tab per prefix
        for prefix in prefixlist:
            # exclude anything with a '.' as those are instance names
            #  handled on a different UI
            if '.' in prefix:
                continue
            if prefix == '_':
                continue
            tab_instances.append(("puppet-%s" % prefix,
                                  PuppetTab(self,
                                            self.request,
                                            prefix=prefix,
                                            tenant_id=self.tenant_id)))

        # + tab
        tab_instances.append(('puppetprefixplus',
                              PlusTab(self, self.request,
                                      tenant_id=self.tenant_id)))
        return tab_instances

    def load_tab_data(self):
        # This ensures that the tab list is updated without
        #  having to rebuild the whole object.
        self._tabs = OrderedDict(self.get_dynamic_tab_list())


class IndexView(tabs.TabbedTableView):
    tab_group_class = PrefixTabs
    template_name = 'project/puppet/prefix_panel.html'
    page_title = _("Prefix Puppet")
