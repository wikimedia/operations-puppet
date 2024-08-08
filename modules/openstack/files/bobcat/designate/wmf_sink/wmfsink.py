# SPDX-License-Identifier: Apache-2.0

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
from wmf_sink.base import BaseAddressWMFHandler
from oslo_log import log as logging

LOG = logging.getLogger(__name__)

cfg.CONF.register_group(cfg.OptGroup(
    name='handler:wmf_sink',
    title="Configuration for WMF-specific event handling)"
))

cfg.CONF.register_opts([
    cfg.ListOpt('notification-topics', default=['monitor']),
    cfg.StrOpt('control-exchange', default='nova'),
    cfg.StrOpt('domain_id', default=None),
    cfg.StrOpt('legacy_domain_id', default=None),
    cfg.StrOpt('site', default='eqiad'),

    cfg.StrOpt('certmanager_user', default='certmanager'),
    cfg.StrOpt('fqdn_format', default=None),
    cfg.StrOpt('puppet_master_host', default=None),

    cfg.StrOpt('region', default=None),
], group='handler:wmf_sink')

cfg.CONF.register_group(cfg.OptGroup(
    name='keystone_authtoken',
    title="Settings for designate to talk to keystone"
))

# We define these here rather than importing
#  from keystoneauth because we need to add
#  in username and password which are no longer
#  defined by the upstream code.  In theory we should
#  be getting these from the context.
cfg.CONF.register_opts([
    cfg.StrOpt('www_authenticate_uri', default=''),
    cfg.StrOpt('username', default=''),
    cfg.StrOpt('password', default=''),
], group='keystone_authtoken')


class NovaFixedWMFHandler(BaseAddressWMFHandler):
    """ Handler for Nova's notifications """
    __plugin_name__ = 'wmf_sink'

    def get_exchange_topics(self):
        exchange = cfg.CONF[self.name].control_exchange

        topics = [topic for topic in cfg.CONF[self.name].notification_topics]

        return (exchange, topics)

    def get_event_types(self):
        return [
            'compute.instance.delete.end',
        ]

    def process_notification(self, context, event_type, payload):
        LOG.debug('received notification - %s' % event_type)

        # This plugin only handles cleanup.
        if event_type == 'compute.instance.delete.end':
            try:
                self._delete(payload,
                             resource_id=payload['instance_id'],
                             resource_type='instance')
            except Exception:
                LOG.exception(
                    "Unhandled exception when processing compute.instance.delete.start notification"
                )
        else:
            raise ValueError('NovaFixedHandler received an invalid event type')
