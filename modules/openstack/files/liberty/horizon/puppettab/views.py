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

from puppet_config import puppet_config

import puppet_roles

import yaml

logging.basicConfig()
LOG = logging.getLogger(__name__)


class EditHieraForm(forms.SelfHandlingForm):
    fqdn = forms.CharField(widget=forms.HiddenInput())
    tenant_id = forms.CharField(widget=forms.HiddenInput())
    hieradata = forms.CharField(label="Instance hiera config:",
                                widget=forms.Textarea(attrs={
                                                      'cols': 80,
                                                      'rows': 15}),
                                required=False)

    def __init__(self, request, *args, **kwargs):
        super(EditHieraForm, self).__init__(request, *args, **kwargs)

    def clean(self):
        cleaned_data = super(EditHieraForm, self).clean()
        return cleaned_data

    def handle(self, request, data):
        config = puppet_config(data['fqdn'], data['tenant_id'])
        config.set_hiera(yaml.safe_load(data['hieradata']))
        return True


class EditHieraView(forms.ModalFormView):
    form_class = EditHieraForm
    form_id = "edit_hiera_form"
    modal_header = _("Edit Hiera")
    submit_label = _("Apply Changes")
    submit_url = "horizon:project:puppet:edithiera"
    template_name = "project/puppet/edithiera.html"
    context_object_name = 'hieraconfig'

    def get_context_data(self, **kwargs):
        context = super(EditHieraView, self).get_context_data(**kwargs)
        context['fqdn'] = self.fqdn
        context['hieradata'] = self.hieradata.hiera
        urlkwargs = {
            'fqdn': self.fqdn,
            'tenantid': self.tenant_id,
            'instanceid': self.instance_id,
        }
        context['submit_url'] = urlresolvers.reverse(self.submit_url,
                                                     kwargs=urlkwargs)
        return context

    def get_success_url(self):
        success_url = "horizon:project:instances:detail"
        return urlresolvers.reverse(success_url, args=[self.instance_id])

    def get_fqdn(self):
        return self.kwargs['fqdn']

    def get_tenant_id(self):
        return self.kwargs['tenantid']

    def get_instance_id(self):
        return self.kwargs['instanceid']

    def get_initial(self):
        initial = {}
        self.fqdn = self.get_fqdn()
        self.tenant_id = self.get_tenant_id()
        self.instance_id = self.get_instance_id()
        self.hieradata = puppet_config(self.fqdn, self.tenant_id)
        initial['hieradata'] = self.hieradata.hiera
        initial['fqdn'] = self.fqdn
        initial['tenant_id'] = self.tenant_id

        return initial


class ApplyRoleForm(forms.SelfHandlingForm):
    def __init__(self, request, *args, **kwargs):
        super(ApplyRoleForm, self).__init__(request, *args, **kwargs)
        initial = kwargs.get('initial', {})
        self.instance_id = initial['instance_id']
        self.tenant_id = initial['tenant_id']
        self.fqdn = initial['fqdn']
        self.role = initial['puppet_role']
        if self.role.params:
            for key in self.role.params.keys():
                defaultval = self.role.params.get(key, '')
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
        config = puppet_config(self.fqdn, self.tenant_id)
        config.apply_role(self.role, data)
        return True


class ApplyRoleView(forms.ModalFormView):
    form_class = ApplyRoleForm
    form_id = "apply_role_form"
    modal_header = _("Apply Role")
    submit_label = _("Apply")
    submit_url = "horizon:project:puppet:applypuppetrole"
    template_name = "project/puppet/apply.html"
    context_object_name = 'puppetrole'

    puppetrole_name = forms.CharField(widget=forms.HiddenInput())

    def get_context_data(self, **kwargs):
        context = super(ApplyRoleView, self).get_context_data(**kwargs)
        context['puppetrole'] = self.puppet_role
        urlkwargs = {
            'fqdn': self.fqdn,
            'tenantid': self.tenant_id,
            'instanceid': self.instance_id,
            'roleid': self.role_id,
        }
        context['fqdn'] = self.fqdn
        context['submit_url'] = urlresolvers.reverse(self.submit_url,
                                                     kwargs=urlkwargs)
        if self.puppet_role.docs:
            context['DocsCaption'] = _('Description:')
        else:
            context['DocsCaption'] = _('(No Description)')
        if self.puppet_role.params:
            context['ParamsCaption'] = _('Parameters:')
        else:
            context['ParamsCaption'] = _('(No Parameters)')
        return context

    def get_success_url(self):
        success_url = "horizon:project:instances:detail"
        return urlresolvers.reverse(success_url, args=[self.instance_id])

    def get_puppet_role(self):
        rolename = self.kwargs['roleid']
        puppet_role = puppet_roles.get_role_by_name(rolename)
        return puppet_role

    def get_fqdn(self):
        return self.kwargs['fqdn']

    def get_tenant_id(self):
        return self.kwargs['tenantid']

    def get_instance_id(self):
        return self.kwargs['instanceid']

    def get_initial(self):
        initial = {}
        self.fqdn = self.get_fqdn()
        self.tenant_id = self.get_tenant_id()
        self.instance_id = self.get_instance_id()
        self.role_id = self.kwargs['roleid']
        self.puppet_role = self.get_puppet_role()
        self.instance_id = self.get_instance_id()
        initial['puppet_role'] = self.puppet_role
        initial['instance_id'] = self.instance_id
        initial['tenant_id'] = self.tenant_id
        initial['fqdn'] = self.fqdn
        return initial


class RemoveRoleForm(forms.SelfHandlingForm):
    def __init__(self, request, *args, **kwargs):
        super(RemoveRoleForm, self).__init__(request, *args, **kwargs)
        initial = kwargs.get('initial', {})
        self.instance_id = initial['instance_id']
        self.tenant_id = initial['tenant_id']
        self.fqdn = initial['fqdn']
        self.role = initial['puppet_role']

    def handle(self, request, data):
        config = puppet_config(self.fqdn, self.tenant_id)
        config.remove_role(self.role)
        return True


class RemoveRoleView(forms.ModalFormView):
    form_class = RemoveRoleForm
    form_id = "remove_role_form"
    modal_header = _("Remove Role")
    submit_label = _("Remove")
    submit_url = "horizon:project:puppet:removepuppetrole"
    template_name = "project/puppet/remove.html"
    context_object_name = 'puppetrole'

    puppetrole_name = forms.CharField(widget=forms.HiddenInput())

    def get_context_data(self, **kwargs):
        context = super(RemoveRoleView, self).get_context_data(**kwargs)
        context['puppetrole'] = self.puppet_role
        urlkwargs = {
            'fqdn': self.fqdn,
            'tenantid': self.tenant_id,
            'instanceid': self.instance_id,
            'roleid': self.role_id,
        }
        context['fqdn'] = self.fqdn
        context['submit_url'] = urlresolvers.reverse(self.submit_url,
                                                     kwargs=urlkwargs)
        if self.puppet_role.docs:
            context['DocsCaption'] = _('Description:')
        else:
            context['DocsCaption'] = _('(No Description)')
        if self.puppet_role.params:
            context['ParamsCaption'] = _('Parameters:')
        else:
            context['ParamsCaption'] = _('(No Parameters)')
        return context

    def get_success_url(self):
        success_url = "horizon:project:instances:detail"
        return urlresolvers.reverse(success_url, args=[self.instance_id])

    def get_puppet_role(self):
        rolename = self.kwargs['roleid']
        puppet_role = puppet_roles.get_role_by_name(rolename)
        return puppet_role

    def get_fqdn(self):
        return self.kwargs['fqdn']

    def get_tenant_id(self):
        return self.kwargs['tenantid']

    def get_instance_id(self):
        return self.kwargs['instanceid']

    def get_initial(self):
        initial = {}
        self.fqdn = self.get_fqdn()
        self.tenant_id = self.get_tenant_id()
        self.instance_id = self.get_instance_id()
        self.role_id = self.kwargs['roleid']
        self.puppet_role = self.get_puppet_role()
        self.instance_id = self.get_instance_id()
        initial['puppet_role'] = self.puppet_role
        initial['instance_id'] = self.instance_id
        initial['tenant_id'] = self.tenant_id
        initial['fqdn'] = self.fqdn
        return initial
