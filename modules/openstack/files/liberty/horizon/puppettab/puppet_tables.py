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

from collections import defaultdict
import logging

from django.core import urlresolvers
from django.utils.translation import ugettext_lazy as _

from horizon import tables

import puppet_roles

logging.basicConfig()
LOG = logging.getLogger(__name__)


def get_formatted_name(classrecord):
    return classrecord.name.split('role::')[1]


def get_formatted_params(classrecord):
    if classrecord.params:
        keysanddefaults = []
        for key in classrecord.params.keys():
            keysanddefaults.append("%s: %s" % (key, classrecord.params[key]))
        return(";\n".join(keysanddefaults))


def get_docs_for_class(classname):
    allroles = puppet_roles.available_roles()
    for role in allroles:
        if role.name.split('role::')[1] == classname:
            if role.docs:
                return {'title': role.docs}
            break
    return {'title': '(No docs available)'}


class RemoveRole(tables.LinkAction):
    name = 'remove'
    verbose_name = _("Remove Role")
    classes = ("ajax-modal",)
    data_type_singular = _("Role")

    policy_rules = (("compute", "compute:delete"),)

    def get_link_url(self, datum):
        url = "horizon:project:puppet:removepuppetrole"
        kwargs = {
            'fqdn': datum.fqdn,
            'tenantid': datum.tenant_id,
            'instanceid': datum.instance_id,
            'roleid': datum.name,
        }
        return urlresolvers.reverse(url, kwargs=kwargs)

    def allowed(self, request, record=None):
        return record.applied


class ApplyRole(tables.LinkAction):
    name = 'apply_role'
    verbose_name = _("Apply Role")
    classes = ("ajax-modal",)
    icon = "plus"
    policy_rules = (("compute", "compute:delete"),)

    def get_link_url(self, datum):
        url = "horizon:project:puppet:applypuppetrole"
        kwargs = {
            'fqdn': datum.fqdn,
            'tenantid': datum.tenant_id,
            'instanceid': datum.instance_id,
            'roleid': datum.name,
        }
        return urlresolvers.reverse(url, kwargs=kwargs)

    def allowed(self, request, record=None):
        return (not record.applied)


def getCategoriesForRole(role):
    categories = set(['all'])
    if 'labs' in role.filter_tags:
        categories.add('labs')
    if 'labs-common' in role.filter_tags:
        categories.add('common')
        categories.add('labs')
    if "labs-project-%s" % role.tenant_id in role.filter_tags:
        categories.add('labs')
        categories.add('project')
    return categories


class UpdateRow(tables.Row):
    ajax = True

    def load_cells(self, role=None):
        super(UpdateRow, self).load_cells(role)
        # Tag the row with the image category for client-side filtering.
        for cat in getCategoriesForRole(self.datum):
            self.classes.append('category-%s' % cat)


class RoleFilter(tables.FixedFilterAction):
    def get_fixed_buttons(self):
        def make_dict(text, tenant, icon):
            return dict(text=text, value=tenant, icon=icon)

        buttons = [make_dict(_('common'), 'common', 'fa-cube'),
                   make_dict(_('labs'), 'labs', 'fa-cubes'),
                   make_dict(_('project'), 'project', 'fa-star'),
                   make_dict(_('all'), 'all', 'fa-warning')]
        return buttons

    def categorize(self, table, roles):
        filtered_dict = defaultdict(list)
        for role in roles:
            categories = getCategoriesForRole(role)
            for cat in categories:
                filtered_dict[cat].append(role)
        return filtered_dict


class PuppetTable(tables.DataTable):
    applied = tables.Column('applied', verbose_name=_('Applied'), status=True)
    name = tables.Column(get_formatted_name,
                         verbose_name=_('Name'),
                         cell_attributes_getter=get_docs_for_class)
    params = tables.Column(get_formatted_params,
                           verbose_name=_('Parameters'),
                           sortable=False)
    instance = tables.Column('instance',
                             verbose_name=_('Instance'),
                             hidden=True)
    tenant = tables.Column('tenant',
                           verbose_name=_('Tenant'),
                           hidden=True)
    tenant = tables.Column('fqdn',
                           verbose_name=_('FQDN'),
                           hidden=True)
    roleid = tables.Column('name', verbose_name=_('ID'), hidden=True)

    class Meta(object):
        name = 'puppet'
        row_actions = (ApplyRole, RemoveRole,)
        table_actions = (RoleFilter,)
        status_columns = ["applied"]
        row_class = UpdateRow

    def get_object_id(self, datum):
        return datum.name

    def render_to_response(self, context, **response_kwargs):
        LOG.warn("render_to_response 2: %s" %
                 self.request.GET.get('format', 'html'))
