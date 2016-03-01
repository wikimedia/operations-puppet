# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import collections
import logging

import django
from django.conf import settings
from django.contrib.auth import authenticate  # noqa
from django.contrib.auth import forms as django_auth_forms
from django import forms
from django.utils.translation import ugettext_lazy as _
from django.views.decorators.debug import sensitive_variables  # noqa

from openstack_auth import exceptions
from openstack_auth import utils


LOG = logging.getLogger(__name__)


class Login(django_auth_forms.AuthenticationForm):
    """Form used for logging in a user.

    Handles authentication with Keystone by providing the domain name, username
    and password. A scoped token is fetched after successful authentication.

    A domain name is required if authenticating with Keystone V3 running
    multi-domain configuration.

    If the user authenticated has a default project set, the token will be
    automatically scoped to their default project.

    If the user authenticated has no default project set, the authentication
    backend will try to scope to the projects returned from the user's assigned
    projects. The first successful project scoped will be returned.

    Inherits from the base ``django.contrib.auth.forms.AuthenticationForm``
    class for added security features.
    """
    region = forms.ChoiceField(label=_("Region"), required=False)
    username = forms.CharField(
        label=_("User Name"),
        widget=forms.TextInput(attrs={"autofocus": "autofocus"}))
    password = forms.CharField(label=_("Password"),
                               widget=forms.PasswordInput(render_value=False))
    totptoken = forms.CharField(label=_("Totp Token"),
                                widget=forms.TextInput())

    def __init__(self, *args, **kwargs):
        super(Login, self).__init__(*args, **kwargs)
        fields_ordering = ['username', 'password', 'totptoken', 'region']
        if getattr(settings,
                   'OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT',
                   False):
            self.fields['domain'] = forms.CharField(
                label=_("Domain"),
                required=True,
                widget=forms.TextInput(attrs={"autofocus": "autofocus"}))
            self.fields['username'].widget = forms.widgets.TextInput()
            fields_ordering = ['domain', 'username', 'password',
                               'totptoken', 'region']
        self.fields['region'].choices = self.get_region_choices()
        if len(self.fields['region'].choices) == 1:
            self.fields['region'].initial = self.fields['region'].choices[0][0]
            self.fields['region'].widget = forms.widgets.HiddenInput()
        elif len(self.fields['region'].choices) > 1:
            self.fields['region'].initial = self.request.COOKIES.get(
                'login_region')

        # if websso is enabled and keystone version supported
        # prepend the websso_choices select input to the form
        if utils.is_websso_enabled():
            initial = getattr(settings, 'WEBSSO_INITIAL_CHOICE', 'credentials')
            self.fields['auth_type'] = forms.ChoiceField(
                label=_("Authenticate using"),
                choices=getattr(settings, 'WEBSSO_CHOICES', ()),
                required=False,
                initial=initial)
            # add auth_type to the top of the list
            fields_ordering.insert(0, 'auth_type')

        # websso is enabled, but keystone version is not supported
        elif getattr(settings, 'WEBSSO_ENABLED', False):
            msg = ("Websso is enabled but horizon is not configured to work " +
                   "with keystone version 3 or above.")
            LOG.warning(msg)
        # Starting from 1.7 Django uses OrderedDict for fields and keyOrder
        # no longer works for it
        if django.VERSION >= (1, 7):
            self.fields = collections.OrderedDict(
                (key, self.fields[key]) for key in fields_ordering)
        else:
            self.fields.keyOrder = fields_ordering

    @staticmethod
    def get_region_choices():
        default_region = (settings.OPENSTACK_KEYSTONE_URL, "Default Region")
        regions = getattr(settings, 'AVAILABLE_REGIONS', [])
        if not regions:
            regions = [default_region]
        return regions

    @sensitive_variables()
    def clean(self):
        default_domain = getattr(settings,
                                 'OPENSTACK_KEYSTONE_DEFAULT_DOMAIN',
                                 'Default')
        username = self.cleaned_data.get('username')
        password = self.cleaned_data.get('password')
        token = self.cleaned_data.get('totptoken')
        region = self.cleaned_data.get('region')
        domain = self.cleaned_data.get('domain', default_domain)

        if not (username and password and token):
            # Don't authenticate, just let the other validators handle it.
            return self.cleaned_data

        try:
            self.user_cache = authenticate(request=self.request,
                                           username=username,
                                           password=password,
                                           totp=token,
                                           user_domain_name=domain,
                                           auth_url=region)
            msg = 'Login successful for user "%(username)s".' % \
                {'username': username}
            LOG.info(msg)
        except exceptions.KeystoneAuthException as exc:
            msg = 'Login failed for user "%(username)s".' % \
                {'username': username}
            LOG.warning(msg)
            raise forms.ValidationError(exc)
        if hasattr(self, 'check_for_test_cookie'):  # Dropped in django 1.7
            self.check_for_test_cookie()
        return self.cleaned_data
