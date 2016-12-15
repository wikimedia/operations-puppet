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

from oslo_log import log as logging
from oslo_config import cfg
from oslo_messaging.notify import notifier

# These imports are for the id monkeypatch at the bottom of this
#  file.  Including up here to make flake8 happy
from keystone.resource import controllers as resource_controllers
from keystone.common import controller
from keystone.common import validation
from keystone.resource import schema
from keystone import notifications
from keystone.i18n import _


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


# HACK ALERT
#
#  Ensure that project id == project name, which supports reverse-
#   compatibility for a bunch of our custom code and tools.
#
#  We can't alter the project ID in a notification hook, because
#   by that time the record has already been created and the old
#   ID returned to Horizon.  So, instead, monkeypatch the function
#   that creates the project and modify the ID.
#
@controller.protected()
@validation.validated(schema.project_create, 'project')
def create_project(self, context, project):
    LOG.warn("Monkypatch in action!  Hacking the new project id to equal "
             "the new project name.")

    ref = self._assign_unique_id(self._normalize_dict(project))
    ref = self._normalize_domain_id(context, ref)

    # This is the only line that's different
    ref['id'] = project['name']

    if ref.get('is_domain'):
        msg = _('The creation of projects acting as domains is not '
                'allowed yet.')
        raise exception.NotImplemented(msg)

    initiator = notifications._get_request_audit_info(context)
    try:
        ref = self.resource_api.create_project(ref['id'], ref,
                                               initiator=initiator)
    except exception.DomainNotFound as e:
        raise exception.ValidationError(e)
    return resource_controllers.ProjectV3.wrap_member(context, ref)


resource_controllers.ProjectV3.create_project = create_project
