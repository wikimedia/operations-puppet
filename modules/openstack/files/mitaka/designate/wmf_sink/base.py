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
from designate.notification_handler.base import BaseAddressHandler
from keystoneclient.auth.identity import v3
from keystoneclient import client
from keystoneclient import exceptions as keystoneexceptions
from keystoneclient.v3 import projects
from keystoneclient import session
from oslo_log import log as logging

import pipes
import subprocess

LOG = logging.getLogger(__name__)
central_api = central_rpcapi.CentralAPI()


class BaseAddressWMFHandler(BaseAddressHandler):

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

        # Clean salt and puppet keys for deleted instance
        if (cfg.CONF[self.name].puppet_key_format and
                cfg.CONF[self.name].puppet_master_host):
            puppetkey = cfg.CONF[self.name].puppet_key_format % event_data
            puppetkey = puppetkey.rstrip('.').encode('utf8')
            LOG.debug('Cleaning puppet key %s' % puppetkey)
            self._run_remote_command(cfg.CONF[self.name].puppet_master_host,
                                     cfg.CONF[self.name].certmanager_user,
                                     'sudo puppet cert clean %s' %
                                     pipes.quote(puppetkey))

        if (cfg.CONF[self.name].salt_key_format and
                cfg.CONF[self.name].salt_master_host):
            saltkey = cfg.CONF[self.name].salt_key_format % event_data
            saltkey = saltkey.rstrip('.').encode('utf8')
            LOG.debug('Cleaning salt key %s' % saltkey)
            self._run_remote_command(cfg.CONF[self.name].salt_master_host,
                                     cfg.CONF[self.name].certmanager_user,
                                     'sudo salt-key -y -d  %s' %
                                     pipes.quote(saltkey))

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
