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

from wikistatus import pageeditor

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
                    default=['identity.project.deleted',
                             'identity.project.created',
                             'identity.role_assignment.created',
                             'identity.role_assignment.deleted'],
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
        self.page_editor = pageeditor.PageEditor()

    def _on_project_delete(self, project_id):
        LOG.debug("Beginning wmf hooks for project deletion: %s" % project_id)

        resource_name = project_id
        self.page_editor.edit_page("", resource_name, True)

    def _get_role_dict(self):
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

        return roledict

    def _on_project_create(self, project_id):
        LOG.debug("Beginning wmf hooks for project creation: %s" % project_id)

        roledict = self._get_role_dict()
        self.assignment_api.add_role_to_user_and_project(CONF.admin_user,
                                                         project_id,
                                                         roledict[CONF.admin_role_name])
        self.assignment_api.add_role_to_user_and_project(CONF.admin_user,
                                                         project_id,
                                                         roledict[CONF.user_role_name])
        self.assignment_api.add_role_to_user_and_project(CONF.observer_user,
                                                         project_id,
                                                         roledict[CONF.observer_role_name])

        self._update_project_page(project_id)

    def _get_role_assignments(self, project_id):
        roledict = self._get_role_dict()

        allusers = self.assignment_api.list_user_ids_for_project(project_id)
        admins = []
        users = []
        for user in allusers:
            roles = self.assignment_api.get_roles_for_user_and_project(user, project_id)
            if roledict[CONF.admin_role_name] in roles:
                admins.append(user)
            if roledict[CONF.user_role_name] in roles:
                users.append(user)
        return {CONF.admin_role_name: admins, CONF.user_role_name: users}

    def _update_project_page(self, project_id, role_assignments=None):
        if not role_assignments:
            role_assignments = self._get_role_assignments(project_id)

        # Create wikitech project page
        resource_name = project_id
        template_param_dict = {}
        template_param_dict['Resource Type'] = 'project'
        template_param_dict['Project Name'] = project_id

        admins = ",".join(["User:%s" % user
                           for user in role_assignments[CONF.admin_role_name]])
        template_param_dict['Admins'] = admins

        members = ",".join(["User:%s" % user
                            for user in role_assignments[CONF.user_role_name]])
        template_param_dict['Members'] = members

        fields_string = ""
        for key in template_param_dict:
            fields_string += "\n|%s=%s" % (key, template_param_dict[key])

        self.page_editor.edit_page(fields_string, resource_name, False,
                                   template='Nova Resource')

    def notify(self, context, message, priority, retry=False):
        event_type = message.get('event_type')

        if event_type == 'identity.project.deleted':
            self._on_project_delete(message['payload']['resource_info'])

        if event_type == 'identity.project.created':
            self._on_project_create(message['payload']['resource_info'])

        if event_type == 'identity.role_assignment.created':
            self._update_project_page(message['payload']['project'])

        if event_type == 'identity.role_assignment.deleted':
            # This is a weird special case... Keystone is dumb and
            #  emits the notification /before/ updating the DB, so we have
            #  to explicitly update our role list.
            assignments = self._get_role_assignments(message['payload']['project'])
            role = message['payload']['role']
            user = message['payload']['user']
            roledict = self._get_role_dict()
            for name in roledict.keys():
                if role == roledict[name]:
                    assignments[name].remove(user)
                    break
            self._update_project_page(message['payload']['project'], assignments)

        # Eventually this will be used to update project resource pages:
        if event_type in CONF.wmf_keystone_eventtype_blacklist:
            return
        if event_type not in CONF.wmf_keystone_eventtype_whitelist:
            return

        return
