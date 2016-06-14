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
from django.utils.safestring import mark_safe
from django.utils.translation import ugettext_lazy as _

from horizon import forms
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
    data_type_singular = _("Role")

    policy_rules = (("compute", "compute:delete"),)

    def get_link_url(self, datum):
        return "%s?%s" % ("removepuppetrole", datum.name)

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
            'instanceid': datum.instance.id,
            'roleid': datum.name,
        }
        return urlresolvers.reverse(url, kwargs=kwargs)

    def allowed(self, request, record=None):
        return (not record.applied)


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
    roleid = tables.Column('name', verbose_name=_('ID'), hidden=True)

    class Meta(object):
        name = 'puppet'
        row_actions = (ApplyRole, RemoveRole,)

        # FIXME:  Add CSS magic to use this to highlight
        #         applied records in the table
        row_attrs = {
            'role_applied': lambda record: record.applied
        }

    def get_object_id(self, datum):
        return datum.name


class ApplyRoleForm(forms.SelfHandlingForm):
    def __init__(self, request, *args, **kwargs):
        super(ApplyRoleForm, self).__init__(request, *args, **kwargs)
        initial = kwargs.get('initial', {})
        LOG.warn('initial: %s' % initial)
        role = initial['puppet_role']
        if role.params:
            for key in role.params.keys():
                defaultval = role.params.get(key, '')
                if defaultval:
                    defaultval = "default: %s" % defaultval
                self.fields[key] = forms.CharField(
                    label=mark_safe("%s  <i><small>%s</small></i>" % (
                        key,
                        defaultval)),
                    required=False
                )

    def clean(self):
        cleaned_data = super(ApplyRoleForm, self).clean()
        return cleaned_data

    def handle(self, request, data):
        pass


class ApplyView(forms.ModalFormView):
    form_class = ApplyRoleForm
    form_id = "apply_role_form"
    modal_header = _("Apply Role")
    submit_label = _("Apply")
    # Fixme:  make the apply button do things
    # submit_url = reverse_lazy("applypuppetrole")
    # success_url = reverse_lazy('horizon:project:instances:detail')
    template_name = "project/puppet/apply.html"
    context_object_name = 'puppetrole'
    page_title = _("Create a Proxy")

    puppetrole_name = forms.CharField(widget=forms.HiddenInput())

    def get_context_data(self, **kwargs):
        context = super(ApplyView, self).get_context_data(**kwargs)
        context['puppetrole'] = self.puppet_role
        context['instanceid'] = self.instance_id
        if self.puppet_role.docs:
            context['DocsCaption'] = _('Description:')
        else:
            context['DocsCaption'] = _('(No Description)')
        if self.puppet_role.params:
            context['ParamsCaption'] = _('Parameters:')
        else:
            context['ParamsCaption'] = _('(No Parameters)')
        return context

    def get_puppet_role(self):
        rolename = self.kwargs['roleid']
        puppet_role = puppet_roles.get_role_by_name(rolename)
        return puppet_role

    def get_instance_id(self):
        instance_id = self.kwargs['instanceid']
        return instance_id

    def get_initial(self):
        initial = {}
        self.puppet_role = self.get_puppet_role()
        self.instance_id = self.get_instance_id()
        initial['puppet_role'] = self.puppet_role
        return initial
