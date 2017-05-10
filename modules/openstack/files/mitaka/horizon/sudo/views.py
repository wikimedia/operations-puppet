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
from django.core.validators import URLValidator
from django.utils.safestring import mark_safe
from django.utils.translation import ungettext_lazy
from django.utils.translation import ugettext_lazy as _

from horizon import exceptions
from horizon import forms
from horizon import tables

import yaml

import sudorules

logging.basicConfig()
LOG = logging.getLogger(__name__)


class AddRule(tables.LinkAction):
    name = "add"
    verbose_name = _("Add Rule")
    url = "horizon:project:sudo:create"
    classes = ("ajax-modal",)
    icon = "plus"
    # todo:  Make real nova policy rules for this
    policy_rules = (("dns", "create_record"),)


class ModifyRule(tables.LinkAction):
    name = "modify"
    verbose_name = _("Modify Rule")
    url = "horizon:project:sudo:modify"
    classes = ("ajax-modal",)

    # todo:  Make real nova policy rules for this
    policy_rules = (("dns", "create_record"),)


class DeleteRule(tables.DeleteAction):

    @staticmethod
    def action_present(count):
        return ungettext_lazy(u"Delete Rule", u"Delete Rules", count)

    @staticmethod
    def action_past(count):
        return ungettext_lazy(u"Deleted Rule", u"Deleted Rules", count)

    # todo:  Make real nova policy rules for this
    policy_rules = (("dns", "create_record"),)

    def delete(self, request, obj_id):
        LOG.warning("Delete %s" % obj_id)



class SudoTable(tables.DataTable):
    name = tables.Column("name", verbose_name=_("Sudo policy name"),)
    users = tables.Column("users_hr", verbose_name=_("Users"),)
    runas = tables.Column("runas_hr", verbose_name=_("Allow running as"),)
    commands = tables.Column("commands_hr", verbose_name=_("Commands"),)
    options = tables.Column("options_hr", verbose_name=_("Options"),)
    authenticate = tables.Column("authenticate", verbose_name=_("Require Password"),)

    class Meta(object):
        name = "proxies"
        verbose_name = _("Sudo Policies")
        table_actions = (AddRule, DeleteRule, )
        row_actions = (ModifyRule, DeleteRule, )


def get_sudo_rule_list(request):
    project = request.user.tenant_id
    rules = []
    try:
        rules = sudorules.rules_for_project(project)
    except Exception:
        exceptions.handle(request, _("Unable to retrieve sudo rules."))
    return rules


class IndexView(tables.DataTableView):
    table_class = SudoTable
    template_name = 'project/sudo/index.html'
    page_title = _("Sudo Policies")

    def get_data(self):
        return get_sudo_rule_list(self.request)
