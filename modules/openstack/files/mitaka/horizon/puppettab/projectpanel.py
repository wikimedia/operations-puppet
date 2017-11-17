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

from django.utils.translation import ugettext_lazy as _
import horizon

from horizon import tabs

import openstack_dashboard.dashboards.project.instances.tabs as instancetabs
from wikimediapuppettab.tab import PuppetTab

logging.basicConfig()
LOG = logging.getLogger(__name__)


class ProjectPuppetPanel(horizon.Panel):
    name = _("Project Puppet")
    slug = "puppet"

    @staticmethod
    def can_register():
        # Hacky hook
        #  While we're here, add tabs to the instance detail view as well
        instancetabs.InstanceDetailTabs.tabs += (PuppetTab,)
        return True


class ProjectTabs(tabs.TabGroup):
    slug = "project_puppet"
    tabs = (PuppetTab, )
    sticky = True


class IndexView(tabs.TabbedTableView):
    tab_group_class = ProjectTabs
    template_name = 'project/puppet/project_panel.html'
    page_title = _("Project Puppet")

    def get_tabs(self, request, *args, **kwargs):
        if self._tab_group is None:
            tenant_id = self.request.user.tenant_id
            caption = _("These puppet settings will affect all VMs"
                        " in the %s project.") % tenant_id
            self._tab_group = self.tab_group_class(request,
                                                   prefix='_',
                                                   caption=caption,
                                                   tenant_id=tenant_id,
                                                   **kwargs)
        return self._tab_group
