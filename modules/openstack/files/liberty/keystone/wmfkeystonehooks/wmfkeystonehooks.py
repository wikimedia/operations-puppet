# Copyright 2016 Andrew Bogott for the Wikimedia Foundation
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

from keystone.common import dependency
from keystone import exception

from keystone.resource.backends import sql as sql_backend
from keystone.common import sql

from oslo_log import log as logging
from oslo_config import cfg
from oslo_messaging.notify import notifier

LOG = logging.getLogger('nova.%s' % __name__)

wmfkeystone_opts = [
    cfg.StrOpt('admin_user',
               default='novaadmin',
               help='Admin user to add to all new projects'),
    cfg.StrOpt('observer_user',
               default='novaobserver',
               help='Observer user to add to all new projects'),
    cfg.StrOpt('observer_role_name',
               default='observer',
               help='Name of observer role'),
    cfg.StrOpt('user_role_name',
               default='user',
               help='Name of simple project user role'),
    cfg.StrOpt('admin_role_name',
               default='projectadmin',
               help='Name of project-local admin role'),
    cfg.MultiStrOpt('wmf_keystone_eventtype_whitelist',
                    default=['identity.project.deleted', 'identity.project.created'],
                    help='Event types to always handle.'),
    cfg.MultiStrOpt('wmf_keystone_eventtype_blacklist',
                    default=[],
                    help='Event types to always ignore.'
                    'In the event of a conflict, '
                    'this overrides the whitelist.')
    ]


CONF = cfg.CONF
CONF.register_opts(wmfkeystone_opts)


@dependency.requires('assignment_api', 'resource_api', 'role_api')
class KeystoneHooks(notifier._Driver):
    """Notifier class which handles extra project creation/deletion bits
    """
    def __init__(self, conf, topics, transport, version=1.0):
        pass

    def _on_project_delete(self, project_id):
        LOG.warning("Beginning wmf hooks for project deletion: %s" % project_id)

    def _on_project_create(self, project_id):

        LOG.warning("Beginning wmf hooks for project creation: %s" % project_id)

        # ====================================
        # Change project id to == project name
        #
        # ====================================
        project = self.resource_api.get_project(project_id)
        name = project['name']

        # We have to do this by hand because the library functions
        #  wisely decline to modify a record id.
        with sql.transaction() as session:
            project_ref = session.query(sql_backend.Project).get(project_id)
            # Kids, don't try this at home!
            setattr(project_ref, 'id', name)

        project_id = name

        # ===============================
        # Add default roles to new project
        # ===============================

        rolelist = self.role_api.list_roles()
        roledict = {}
        # Make a dict to relate role names to ids
        for role in rolelist:
            roledict[role['name']] = role['id']
        if CONF.observer_role_name not in roledict.keys():
            LOG.error("Failed to find id for role %s" % CONF.observer_role_name)
            raise exception.NotImplemented()
        if CONF.admin_role_name not in roledict.keys():
            LOG.error("Failed to find id for role %s" % CONF.admin_role_name)
            raise exception.NotImplemented()
        if CONF.user_role_name not in roledict.keys():
            LOG.error("Failed to find id for role %s" % CONF.user_role_name)
            raise exception.NotImplemented()

        self.assignment_api.add_role_to_user_and_project(CONF.admin_user,
                                                         project_id,
                                                         roledict[CONF.admin_role_name])
        self.assignment_api.add_role_to_user_and_project(CONF.admin_user,
                                                         project_id,
                                                         roledict[CONF.user_role_name])
        self.assignment_api.add_role_to_user_and_project(CONF.observer_user,
                                                         project_id,
                                                         roledict[CONF.observer_role_name])

    def notify(self, context, message, priority, retry=False):
        event_type = message.get('event_type')

        if event_type == 'identity.project.deleted':
            self._on_project_delete(message['payload']['resource_info'])

        if event_type == 'identity.project.created':
            self._on_project_create(message['payload']['resource_info'])

        # Eventually this will be used to update project resource pages:
        if event_type in CONF.wmf_keystone_eventtype_blacklist:
            return
        if event_type not in CONF.wmf_keystone_eventtype_whitelist:
            return

        return
