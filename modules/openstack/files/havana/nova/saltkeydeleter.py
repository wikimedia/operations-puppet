# Copyright 2014 Ariel Glenn
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
from nova.openstack.common import log as logging

import salt.client
import salt.key

LOG = logging.getLogger('nova.plugin.%s' % __name__)


class SaltKeyDeleter(object):
    '''
    delete salt keys for an instance upon deletion;
    this requires the salt master to be located on the
    same host where this script runs, and nova events to
    be available on that host as well
    '''
    @staticmethod
    def notify(ctxt, message):
        '''
        receive events and if the event is an instance
        deletion, delete the salt key for the instance
        '''
        event_type = message.get('event_type')
        if event_type != 'compute.instance.delete.end':
            return

        payload = message['payload']
        instance = payload['instance_id']
        instance_name = payload['display_name']

        LOG.debug("saltkeydeletion:  would delete key for instance %s (%s)"
                  % (instance, instance_name))

        # don't do this yet, let's see what that instance id
        # and display name look like
        # SaltKeyDeleter.delete_salt_key(instance, instance_name)

    @staticmethod
    def delete_salt_key(instance, instance_name):
        '''
        delete salt key for the given ec2id name and/or human-friendly
        instance name

        failures are ignored, as we expect that the salt key
        will only exist for one of those names; it's also possible
        for an instance to be deleted that never had a salt key due
        to setup issues
        '''
        client = salt.client.LocalClient()
        key_manager = salt.key.Key(client.opts)

        # try deletion of key with both ec2id and instance name
        # to cover all the bases
        try:
            key_manager.delete_key(instance)
            key_manager.delete_key(instance_name)
        except:
            # fixme do we want to log these? will be at least one
            # failure per deletion attempt, is that too verbose?
            pass

notifier = SaltKeyDeleter


def notify(ctxt, message):
    '''
    nova notifier framework calls this method

    upon receipt of an instance deletion event,
    delete its salt keys
    '''
    notifier.notify(ctxt, message)
