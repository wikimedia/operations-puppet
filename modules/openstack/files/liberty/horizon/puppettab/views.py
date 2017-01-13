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
from django.utils.translation import ugettext_lazy as _

from horizon import forms

from puppet_config import puppet_config

import puppet_roles

import yaml

logging.basicConfig()
LOG = logging.getLogger(__name__)


class EditHieraForm(forms.SelfHandlingForm):
    prefix = forms.CharField(widget=forms.HiddenInput())
    tenant_id = forms.CharField(widget=forms.HiddenInput())
    hieradata = forms.CharField(label=_("Instance hiera config:"),
                                widget=forms.Textarea(attrs={
                                                      'cols': 80,
                                                      'rows': 15}),
                                required=False)

    def handle(self, request, data):
        config = puppet_config(data['prefix'], data['tenant_id'])
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
        context['prefix'] = self.prefix
        context['hieradata'] = self.hieradata.hiera
        urlkwargs = {
            'prefix': self.prefix,
            'tenantid': self.tenant_id,
        }
        context['submit_url'] = urlresolvers.reverse(self.submit_url,
                                                     kwargs=urlkwargs)
        return context

    def get_success_url(self):
        validate = URLValidator()
        refer = self.request.META.get('HTTP_REFERER', '/')
        validate(refer)
        return refer

    def get_prefix(self):
        return self.kwargs['prefix']

    def get_tenant_id(self):
        return self.kwargs['tenantid']

    def get_initial(self):
        initial = {}
        self.prefix = self.get_prefix()
        self.tenant_id = self.get_tenant_id()
        self.hieradata = puppet_config(self.prefix, self.tenant_id)
        initial['hieradata'] = self.hieradata.hiera
        initial['prefix'] = self.prefix
        initial['tenant_id'] = self.tenant_id

        return initial


class RoleViewBase(forms.ModalFormView):
    context_object_name = 'puppetrole'

    puppetrole_name = forms.CharField(widget=forms.HiddenInput())

    def get_context_data(self, **kwargs):
        context = super(RoleViewBase, self).get_context_data(**kwargs)
        context['puppetrole'] = self.puppet_role
        urlkwargs = {
            'prefix': self.prefix,
            'tenantid': self.tenant_id,
            'roleid': self.role_id,
        }
        context['prefix'] = self.prefix
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
        validate = URLValidator()
        refer = self.request.META.get('HTTP_REFERER', '/')
        validate(refer)
        return refer

    def get_puppet_role(self):
        rolename = self.kwargs['roleid']
        puppet_role = puppet_roles.get_role_by_name(rolename)
        return puppet_role

    def get_prefix(self):
        return self.kwargs['prefix']

    def get_tenant_id(self):
        return self.kwargs['tenantid']

    def get_initial(self):
        initial = {}
        self.prefix = self.get_prefix()
        self.tenant_id = self.get_tenant_id()
        self.role_id = self.kwargs['roleid']
        self.puppet_role = self.get_puppet_role()
        initial['puppet_role'] = self.puppet_role
        initial['tenant_id'] = self.tenant_id
        initial['prefix'] = self.prefix
        return initial


class ApplyRoleForm(forms.SelfHandlingForm):
    def __init__(self, request, *args, **kwargs):
        super(ApplyRoleForm, self).__init__(request, *args, **kwargs)
        initial = kwargs.get('initial', {})
        self.tenant_id = initial['tenant_id']
        self.prefix = initial['prefix']
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

    def handle(self, request, data):
        config = puppet_config(self.prefix, self.tenant_id)
        config.apply_role(self.role, data)
        return True


class ApplyRoleView(RoleViewBase):
    form_class = ApplyRoleForm
    form_id = "apply_role_form"
    modal_header = _("Apply Class")
    submit_label = _("Apply")
    submit_url = "horizon:project:puppet:applypuppetrole"
    template_name = "project/puppet/apply.html"


class RemoveRoleForm(forms.SelfHandlingForm):
    def __init__(self, request, *args, **kwargs):
        super(RemoveRoleForm, self).__init__(request, *args, **kwargs)
        initial = kwargs.get('initial', {})
        self.tenant_id = initial['tenant_id']
        self.prefix = initial['prefix']
        self.role = initial['puppet_role']

    def handle(self, request, data):
        config = puppet_config(self.prefix, self.tenant_id)
        config.remove_role(self.role)
        return True


class RemoveRoleView(RoleViewBase):
    form_class = RemoveRoleForm
    form_id = "remove_role_form"
    modal_header = _("Remove Class")
    submit_label = _("Remove")
    submit_url = "horizon:project:puppet:removepuppetrole"
    template_name = "project/puppet/remove.html"


class RemovePrefixForm(forms.SelfHandlingForm):
    def __init__(self, request, *args, **kwargs):
        super(RemovePrefixForm, self).__init__(request, *args, **kwargs)
        initial = kwargs.get('initial', {})
        self.tenant_id = initial['tenant_id']
        self.prefix = initial['prefix']

    def handle(self, request, data):
        puppet_config.delete_prefix(self.tenant_id, self.prefix)
        return True


class RemovePrefixView(forms.ModalFormView):
    form_class = RemovePrefixForm
    form_id = "remove_prefix_form"
    modal_header = _("Remove Prefix")
    submit_label = _("Remove")
    submit_url = "horizon:project:puppet:removepuppetprefix"
    template_name = "project/puppet/removeprefix.html"

    def get_prefix(self):
        return self.kwargs['prefix']

    def get_tenant_id(self):
        return self.kwargs['tenantid']

    def get_initial(self):
        initial = {}
        self.prefix = self.get_prefix()
        self.tenant_id = self.get_tenant_id()
        initial['prefix'] = self.prefix
        initial['tenant_id'] = self.tenant_id

        return initial

    def get_context_data(self, **kwargs):
        context = super(RemovePrefixView, self).get_context_data(**kwargs)
        context['prefix'] = self.prefix
        urlkwargs = {
            'prefix': self.prefix,
            'tenantid': self.tenant_id,
        }
        context['prefix'] = self.prefix
        context['submit_url'] = urlresolvers.reverse(self.submit_url,
                                                     kwargs=urlkwargs)
        return context

    def get_success_url(self):
        validate = URLValidator()
        refer = self.request.META.get('HTTP_REFERER', '/')
        validate(refer)
        return refer


class EditOtherClassesForm(forms.SelfHandlingForm):
    prefix = forms.CharField(widget=forms.HiddenInput())
    tenant_id = forms.CharField(widget=forms.HiddenInput())
    classes = forms.CharField(label=_("Other classes:"),
                              widget=forms.Textarea(attrs={
                                                    'cols': 80,
                                                    'rows': 15}),
                              required=False)

    def handle(self, request, data):
        other_class_list = [cls.strip() for cls in data['classes'].strip().split("\n") if cls]
        config = puppet_config(data['prefix'], data['tenant_id'])
        config.set_other_class_list(other_class_list)
        return True


class EditOtherClassesView(forms.ModalFormView):
    form_class = EditOtherClassesForm
    form_id = "edit_otherclasses_form"
    modal_header = _("Edit Other Classes")
    submit_label = _("Apply Changes")
    submit_url = "horizon:project:puppet:editotherclasses"
    template_name = "project/puppet/editotherclasses.html"
    context_object_name = 'otherclassesconfig'

    def get_context_data(self, **kwargs):
        context = super(EditOtherClassesView, self).get_context_data(**kwargs)
        context['prefix'] = self.prefix
        context['classes'] = self.classdata.other_classes
        urlkwargs = {
            'prefix': self.prefix,
            'tenantid': self.tenant_id,
        }
        context['submit_url'] = urlresolvers.reverse(self.submit_url,
                                                     kwargs=urlkwargs)
        return context

    def get_success_url(self):
        validate = URLValidator()
        refer = self.request.META.get('HTTP_REFERER', '/')
        validate(refer)
        return refer

    def get_prefix(self):
        return self.kwargs['prefix']

    def get_tenant_id(self):
        return self.kwargs['tenantid']

    def get_initial(self):
        initial = {}
        self.prefix = self.get_prefix()
        self.tenant_id = self.get_tenant_id()
        self.classdata = puppet_config(self.prefix, self.tenant_id)
        initial['classes'] = self.classdata.other_classes_text
        initial['prefix'] = self.prefix
        initial['tenant_id'] = self.tenant_id

        return initial
