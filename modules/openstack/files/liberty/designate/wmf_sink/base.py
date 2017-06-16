# Copyright 2015 Andrew Bogott for the Wikimedia Foundation
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

from oslo_config import cfg
from designate.central import rpcapi as central_rpcapi
from designate.context import DesignateContext
from designate.notification_handler.base import BaseAddressHandler
from keystoneclient.auth.identity import generic
from keystoneclient import session as keystone_session
from keystoneclient.v3 import client as keystone_client
from oslo_log import log as logging

import pipes
import requests
import subprocess

LOG = logging.getLogger(__name__)
central_api = central_rpcapi.CentralAPI()


class BaseAddressWMFHandler(BaseAddressHandler):
    proxy_endpoint = ""

    def _delete(self, extra, managed=True, resource_id=None,
                resource_type='instance', criterion={}):
        """
        Handle a generic delete of a fixed ip within a domain

        :param criterion: Criterion to search and destroy records
        """

        domain = self.get_domain(cfg.CONF[self.name].domain_id)

        data = extra.copy()
        LOG.debug('Event data: %s' % data)
        data['domain'] = domain['name']

        data['project_name'] = data['tenant_id']

        event_data = data.copy()

        fqdn = cfg.CONF[self.name].fqdn_format % event_data
        fqdn = fqdn.rstrip('.').encode('utf8')

        # Clean salt and puppet keys for deleted instance
        if cfg.CONF[self.name].puppet_master_host:
            LOG.debug('Cleaning puppet key %s' % fqdn)
            self._run_remote_command(cfg.CONF[self.name].puppet_master_host,
                                     cfg.CONF[self.name].certmanager_user,
                                     'sudo puppet cert clean %s' %
                                     pipes.quote(fqdn))

        if cfg.CONF[self.name].salt_master_host:
            LOG.debug('Cleaning salt key %s' % fqdn)
            self._run_remote_command(cfg.CONF[self.name].salt_master_host,
                                     cfg.CONF[self.name].certmanager_user,
                                     'sudo salt-key -y -d  %s' %
                                     pipes.quote(fqdn))

        # Clean up the puppet config for this instance, if there is one
        self._delete_puppet_config(data['tenant_id'], fqdn)

        # Finally, delete any proxy records pointing to this instance.
        #
        # For that, we need the IP which we can dig out of the old DNS record.
        crit = criterion.copy()

        # Make sure we only look at forward records
        crit['domain_id'] = cfg.CONF[self.name].domain_id

        if managed:
            crit.update({
                'managed': managed,
                'managed_resource_id': resource_id,
                'managed_resource_type': resource_type
            })

        context = DesignateContext().elevated()
        context.all_tenants = True
        context.edit_managed_records = True

        records = central_api.find_records(context, crit)

        # We only care about the IP, and that's the same in both records.
        ip = records[0].data
        LOG.debug("Cleaning up proxy records for IP %s" % ip)
        self._delete_proxies_for_ip(data['project_name'], ip)

    @staticmethod
    def _run_remote_command(server, username, command):
        ssh_command = ['/usr/bin/ssh', '-l%s' % username, server, command]

        p = subprocess.Popen(ssh_command,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        (out, error) = p.communicate()
        rcode = p.wait()
        return out, error, rcode

        if rcode:
            LOG.warning('Remote call %s to server %s failed: \n%s\n%s' %
                        (command, server, out, error))
            return False
        return True

    def _delete_puppet_config(self, projectid, fqdn):
        endpoint = cfg.CONF[self.name].puppet_config_backend
        url = "%s/%s/prefix/%s" % (endpoint, projectid, fqdn)
        requests.delete(url, verify=False)
        # Maybe there isn't such a prefix, and this will fail.  No problem!

    def _delete_proxies_for_ip(self, project, ip):
        project_proxies = self._get_proxy_list_for_project(project)
        for proxy in project_proxies:
            if len(proxy['backends']) > 1:
                LOG.warning("This proxy record has multiple backends. "
                            "That's unexpected and not handled, "
                            "we may be leaking proxy records.")
            elif proxy['backends'][0].split(":")[1].strip('/') == ip:
                # found match, deleting.
                LOG.debug("Cleaning up proxy record %s" % proxy)
                domain = proxy['domain']
                endpoint = self._get_proxy_endpoint()
                requrl = endpoint.replace("$(tenant_id)s", project)
                req = requests.delete(requrl + '/mapping/' + domain)
                req.raise_for_status()

    def _get_proxy_list_for_project(self, project):
        endpoint = self._get_proxy_endpoint()
        requrl = endpoint.replace("$(tenant_id)s", project)
        resp = requests.get(requrl + '/mapping')
        if resp.status_code == 400 and resp.text == 'No such project':
            return []
        elif not resp:
            raise Exception("Proxy service request got status " +
                            str(resp.status_code))
        else:
            return resp.json()['routes']

    def _get_proxy_endpoint(self):
        if not self.proxy_endpoint:

            auth = generic.Password(
                auth_url=cfg.CONF['keystone_authtoken'].auth_uri,
                username=cfg.CONF['keystone_authtoken'].admin_user,
                password=cfg.CONF['keystone_authtoken'].admin_password,
                user_domain_name='Default',
                project_domain_name='Default',
                project_name='admin')

            session = keystone_session.Session(auth=auth)

            keystone = keystone_client.Client(
                session=session, interface='public', connect_retries=5)

            services = keystone.services.list()
            for service in services:
                if service.type == 'proxy':
                    serviceid = service.id
                    break

            endpoints = keystone.endpoints.list(service=serviceid)
            for endpoint in endpoints:
                if endpoint.interface == 'public':
                    self.proxy_endpoint = endpoint.url
                    break

            if not self.proxy_endpoint:
                raise Exception("Can't find the public proxy service endpoint.")

        return self.proxy_endpoint
