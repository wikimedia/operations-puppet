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

from django.utils.translation import ugettext_lazy as _
import horizon

from horizon import views

import openstack_dashboard.dashboards.project.instances.tabs as instancetabs
from wikimediapuppettab.tab import PuppetTab


class PuppetTabDummyPanel(horizon.Panel):
    name = _("Dummy")
    slug = "puppet"
    # We need some way to hide the panel menu entry.
    #  Unfortunately, disallowing it prevents loading of
    #  all templates.
    # permissions = ('forbid',)

    @staticmethod
    def can_register():
        # Hacky hook
        #  We don't want to actually add a panel.  But we /do/ want a bunch
        #  of templates and classes and such loaded.  So, I'm overloading
        #  this function to override the things I actually care about.
        instancetabs.InstanceDetailTabs.tabs = (instancetabs.OverviewTab,
                                                instancetabs.LogTab,
                                                PuppetTab,
                                                instancetabs.AuditTab)
        return True


class IndexView(views.HorizonTemplateView):
    table_class = None
    template_name = 'project/puppet/index.html'
    page_title = _("Dummy")
