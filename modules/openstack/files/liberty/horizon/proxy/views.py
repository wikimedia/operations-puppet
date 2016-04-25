# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import logging

from django.conf import settings
from django.core.urlresolvers import reverse_lazy
from django.utils.translation import ungettext_lazy
from django.utils.translation import ugettext_lazy as _

from django.forms import TextInput

from horizon import exceptions
from horizon import forms
from horizon import tables

from openstack_dashboard.api import base, nova

# Designate v1 API, for normal use
import designatedashboard.api.designate as designateapi
from designateclient.v1.records import Record

# Designate v2 API, currently only for wmflabs.org
from keystoneclient.auth.identity import generic as identity_generic
from keystoneclient import session as keystone_session
from designateclient.v2 import client as designateclientv2

import json
import requests
import socket
import urlparse

LOG = logging.getLogger(__name__)


class CreateProxy(tables.LinkAction):
    name = "create"
    verbose_name = _("Create Proxy")
    url = "horizon:project:proxy:create"
    classes = ("ajax-modal",)
    icon = "plus"
    policy_rules = (("dns", "create_record"),)


class DeleteProxy(tables.DeleteAction):
    @staticmethod
    def action_present(count):
        return ungettext_lazy(u"Delete Proxy", u"Delete Proxies", count)

    @staticmethod
    def action_past(count):
        return ungettext_lazy(u"Deleted Proxy", u"Deleted Proxies", count)

    policy_rules = (("dns", "delete_record"),)

    def delete(self, request, obj_id):
        record = obj_id[:obj_id.find('.')]
        domain = obj_id[obj_id.find('.') + 1:]
        if not domain.endswith('.'):
            domain += '.'

        # First let's make sure that this proxy is really ours to delete.
        existing_domains = [proxy.domain for proxy in get_proxy_list(request)]
        if obj_id not in existing_domains:
            raise Exception("Proxy \'%s\' is to be deleted but is not owned by this view." % obj_id)

        if domain == 'wmflabs.org.':
            auth = identity_generic.Password(
                auth_url=base.url_for(request, 'identity'),
                username=getattr(settings, "WMFLABSDOTORG_ADMIN_USERNAME", ''),
                password=getattr(settings, "WMFLABSDOTORG_ADMIN_PASSWORD", ''),
                tenant_name='wmflabsdotorg',
                user_domain_id='default',
                project_domain_id='default'
            )
            c = designateclientv2.Client(session=keystone_session.Session(auth=auth))

            # Delete the record from the wmflabsdotorg project. This is needed since wmflabs.org lives
            #  in that project and designate (quite reasonably) prevents subdomain deletion elsewhere.
            zoneid = None
            for zone in c.zones.list():
                if zone['name'] == 'wmflabs.org.':
                    zoneid = zone['id']
                    break
            else:
                raise Exception("No zone ID")
            recordsetid = None
            for recordset in c.recordsets.list(zoneid):
                if recordset['type'] == 'A' and recordset['name'] == record + '.' + domain:
                    recordsetid = recordset['id']
                    break
            else:
                raise Exception("No recordset ID")
            c.recordsets.delete(zoneid, recordsetid)
        else:
            c = designateapi.designateclient(request)
            domainid = None
            for d in c.domains.list():
                if d.name == domain:
                    domainid = d.id
                    break
            else:
                LOG.warn('Woops! Failed domain ID for domain ' + domain)
                raise Exception("No domain ID")
            recordid = None
            for r in c.records.list(domainid):
                if r.name == obj_id and r.type == 'A':
                    recordid = r.id
                    break
            else:
                LOG.warn('Woops! Failed record ID for record ' + record)
                raise Exception("No record ID")

            c.records.delete(domainid, recordid)

        resp = requests.delete(base.url_for(request, 'proxy') + '/mapping/' + obj_id)
        if not resp:
            raise Exception("Got status " + resp.status_code)


def get_proxy_backends(proxy):
    return ', '.join(proxy.backends)


class ProxyTable(tables.DataTable):
    domain = tables.Column("domain", verbose_name=_("DNS Hostname"),)
    backends = tables.Column(get_proxy_backends, verbose_name=_("Backends"))

    class Meta(object):
        name = "proxies"
        verbose_name = _("Proxies")
        table_actions = (CreateProxy,)
        row_actions = (DeleteProxy,)


class Proxy():
    def __init__(self, domain, backends):
        self.id = self.domain = domain
        self.backends = backends


def get_proxy_list(request):
    try:
        resp = requests.get(base.url_for(request, 'proxy') + '/mapping')
        if resp.status_code == 400 and resp.text == 'No such project':
            proxies = []
        elif not resp:
            raise Exception("Got status " + str(resp.status_code))
        else:
            proxies = [Proxy(route['domain'], route['backends']) for route in resp.json()['routes']]
    except Exception:
        proxies = []
        exceptions.handle(request, _("Unable to retrieve proxies: " + resp.text))
    return proxies


class IndexView(tables.DataTableView):
    table_class = ProxyTable
    template_name = 'project/proxy/index.html'
    page_title = _("Proxies")

    def get_data(self):
        resp = None
        return get_proxy_list(self.request)


class CreateProxyForm(forms.SelfHandlingForm):
    record = forms.RegexField(max_length=255, label=_("Hostname"),
                              regex="^([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])$",
                              error_messages={"invalid":
                                              "This must be a simple hostname without dots or special characters."})
    domain = forms.ChoiceField(widget=forms.Select(), label=_("Domain"))
    backendInstance = forms.ChoiceField(widget=forms.Select(), label=_("Backend instance"))
    backendPort = forms.CharField(widget=TextInput(attrs={'type': 'number'}), label=_("Backend port"))

    def __init__(self, request, *args, **kwargs):
        kwargs['initial']['backendPort'] = 80
        super(CreateProxyForm, self).__init__(request, *args, **kwargs)
        self.fields['backendInstance'].choices = self.populate_instances(request)
        self.fields['domain'].choices = self.populate_domains(request)

    def populate_instances(self, request):
        results = [(None, 'Select an instance')]
        for server in nova.novaclient(request).servers.list():
            results.append((server.networks['public'][0], server.name))
        return results

    def populate_domains(self, request):
        results = [('wmflabs.org.', 'wmflabs.org.')]
        #results = [(None, 'Select a domain'), ('wmflabs.org.', 'wmflabs.org.')]
        #for domain in designateapi.designateclient(request).domains.list():
            #results.append((domain.name, domain.name))
        return results

    def clean(self):
        cleaned_data = super(CreateProxyForm, self).clean()

        # TODO: More useful error if domain is invalid? Currently we rely on designate schema check failing

        if not cleaned_data['backendPort'].isdigit() or int(cleaned_data['backendPort']) > 65535:
            self._errors['backendPort'] = self.error_class([_('Enter a valid port')])

        return cleaned_data

    def handle(self, request, data):
        proxyip = socket.gethostbyname(urlparse.urlparse(base.url_for(request, 'proxy')).hostname)
        if data.get('domain') == 'wmflabs.org.':
            auth = identity_generic.Password(
                auth_url=base.url_for(request, 'identity'),
                username=getattr(settings, "WMFLABSDOTORG_ADMIN_USERNAME", ''),
                password=getattr(settings, "WMFLABSDOTORG_ADMIN_PASSWORD", ''),
                tenant_name='wmflabsdotorg',
                user_domain_id='default',
                project_domain_id='default'
            )
            c = designateclientv2.Client(session=keystone_session.Session(auth=auth))

            LOG.warn('Got create client')
            # Create the record in the wmflabsdotorg project. This is needed since wmflabs.org lives
            #  in that project and designate prevents subdomain creation elsewhere.
            zoneid = None
            for zone in c.zones.list():
                if zone['name'] == 'wmflabs.org.':
                    zoneid = zone['id']
                    break
            else:
                raise Exception("No zone ID")
            LOG.warn('Got zone ID')
            c.recordsets.create(zoneid, data.get('record') + '.wmflabs.org.', 'A', [proxyip])
        else:
            # TODO: Move this to designate v2 API, reuse some code
            c = designateapi.designateclient(request)
            domainid = None
            for domain in c.domains.list():
                if domain.name == data.get('domain'):
                    domainid = domain.id
                    break
            else:
                raise Exception("No domain ID")
            record = Record(name=data.get('record') + '.' + data.get('domain'), type='A', data=proxyip)
            c.records.create(domainid, record)

        d = {
            "backends": ['http://%s:%s' % (
                data.get('backendInstance'),
                data.get('backendPort')
            )],
            "domain": data.get('record') + '.' + data.get('domain').rstrip('.')
        }

        try:
            resp = requests.put(base.url_for(request, 'proxy') + '/mapping', data=json.dumps(d))
            if resp:
                return True
            else:
                raise Exception("Got status: " + resp.status_code)
        except Exception:
            exceptions.handle(self.request, _("Unable to create proxy: " + resp.text))
            return False


class CreateView(forms.ModalFormView):
    form_class = CreateProxyForm
    form_id = "create_proxy_form"
    modal_header = _("Create a Proxy")
    submit_label = _("Create Proxy")
    submit_url = reverse_lazy('horizon:project:proxy:create')
    template_name = 'project/proxy/create.html'
    context_object_name = 'proxy'
    success_url = reverse_lazy("horizon:project:proxy:index")
    page_title = _("Create a Proxy")

    def get_initial(self):
        initial = {}
        for name in ['record', 'domain', 'backendInstance', 'backendPort']:
            tmp = self.request.GET.get(name)
            if tmp:
                initial[name] = tmp
        return initial
