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
    cfg.StrOpt('site', default='eqiad'),

    cfg.ListOpt('puppetdefaultclasses', default=[]),
    cfg.ListOpt('puppetdefaultvars', default=[]),

    cfg.StrOpt('certmanager_user', default='certmanager'),
    cfg.StrOpt('puppet_key_format', default=None),
    cfg.StrOpt('salt_key_format', default=None),
    cfg.StrOpt('puppet_master_host', default=None),
    cfg.StrOpt('salt_master_host', default=None),
], group='handler:wmf_sink')


class NovaFixedWMFHandler(BaseAddressWMFHandler):
    """ Handler for Nova's notifications """
    __plugin_name__ = 'wmf_sink'

    def get_exchange_topics(self):
        exchange = cfg.CONF[self.name].control_exchange

        topics = [topic for topic in cfg.CONF[self.name].notification_topics]

        return (exchange, topics)

    def get_event_types(self):
        return [
            'compute.instance.delete.start',
        ]

    def process_notification(self, context, event_type, payload):
        LOG.debug('received notification - %s' % event_type)

        # This plugin only handles cleanup.
        if event_type == 'compute.instance.delete.start':
            self._delete(payload,
                         resource_id=payload['instance_id'],
                         resource_type='instance')
        else:
            raise ValueError('NovaFixedHandler received an invalid event type')
