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


# This file is a slight modification of the nova notification driver found
#  in the designate source at designate/notification_handler/nova.py

from oslo_config import cfg
from nova_ldap.base import BaseAddressLdapHandler
from oslo_log import log as logging

LOG = logging.getLogger(__name__)

cfg.CONF.register_group(cfg.OptGroup(
    name='handler:nova_ldap',
    title="Configuration for Nova Ldap Handler (WMF-specific transitional)"
))

cfg.CONF.register_opts([
    cfg.ListOpt('notification-topics', default=['monitor']),
    cfg.StrOpt('control-exchange', default='nova'),
    cfg.StrOpt('domain_id', default=None),

    cfg.ListOpt('format', default=[]),
    cfg.StrOpt('ldapusername', default=None),
    cfg.StrOpt('ldappassword', default=None),

    cfg.ListOpt('puppetdefaultclasses', default=[]),
    cfg.ListOpt('puppetdefaultvars', default=[]),

    cfg.StrOpt('certmanager_user', default='certmanager'),
    cfg.StrOpt('puppet_key_format', default=None),
    cfg.StrOpt('salt_key_format', default=None),
    cfg.StrOpt('puppet_master_host', default=None),
    cfg.StrOpt('salt_master_host', default=None),

    cfg.StrOpt('keystone_auth_name', default=None),
    cfg.StrOpt('keystone_auth_pass', default=None),
    cfg.StrOpt('keystone_auth_project', default=None),
    cfg.StrOpt('keystone_auth_url', default=None),
], group='handler:nova_ldap')


class NovaFixedLdapHandler(BaseAddressLdapHandler):
    """ Handler for Nova's notifications """
    __plugin_name__ = 'nova_ldap'

    def get_exchange_topics(self):
        exchange = cfg.CONF[self.name].control_exchange

        topics = [topic for topic in cfg.CONF[self.name].notification_topics]

        return (exchange, topics)

    def get_event_types(self):
        return [
            'compute.instance.create.end',
            'compute.instance.delete.start',
        ]

    def process_notification(self, context, event_type, payload):
        LOG.debug('NovaLdapHandler received notification - %s' % event_type)

        if event_type == 'compute.instance.create.end':
            self._create(payload['fixed_ips'], payload,
                         resource_id=payload['instance_id'],
                         resource_type='instance')

        elif event_type == 'compute.instance.delete.start':
            self._delete(payload,
                         resource_id=payload['instance_id'],
                         resource_type='instance')
        else:
            raise ValueError('NovaFixedHandler received an invalid event type')
