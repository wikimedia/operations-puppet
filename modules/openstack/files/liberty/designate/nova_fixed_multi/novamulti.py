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
from oslo_log import log as logging
from nova_fixed_multi.base import BaseAddressMultiHandler

import sys

LOG = logging.getLogger(__name__)

cfg.CONF.register_group(cfg.OptGroup(
    name='handler:nova_fixed_multi',
    title="Configuration for Nova Notification Handler"
))

cfg.CONF.register_opts([
    cfg.ListOpt('notification-topics', default=['monitor']),
    cfg.StrOpt('control-exchange', default='nova'),
    cfg.StrOpt('domain-id', default=None),
    cfg.MultiStrOpt('format', default=[]),
    cfg.StrOpt('reverse-domain-id', default=None),
    cfg.StrOpt('reverse-format', default=None),

    cfg.StrOpt('keystone_auth_name', default=None),
    cfg.StrOpt('keystone_auth_pass', default=None),
    cfg.StrOpt('keystone_auth_project', default=None),
    cfg.StrOpt('keystone_auth_url', default=None),
], group='handler:nova_fixed_multi')


class NovaFixedMultiHandler(BaseAddressMultiHandler):
    """ Handler for Nova's notifications """
    __plugin_name__ = 'nova_fixed_multi'

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
        LOG.debug('NovaFixedHandler received notification - %s' % event_type)

        if event_type == 'compute.instance.create.end':
            try:
                self._create(payload['fixed_ips'], payload,
                             resource_id=payload['instance_id'],
                             resource_type='instance')
            except:
                LOG.debug("--------------------     Unexpected error: %s" %
                          sys.exc_info()[0])
                LOG.debug("--------------------     (swallowed)")

        elif event_type == 'compute.instance.delete.start':
            try:
                self._delete(resource_id=payload['instance_id'],
                             resource_type='instance')
            except:
                LOG.debug("--------------------     Unexpected error: %s" %
                          sys.exc_info()[0])
                LOG.debug("--------------------     (swallowed)")
        else:
            raise ValueError('NovaFixedHandler received an invalid event type')
