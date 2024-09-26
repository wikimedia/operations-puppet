#!/usr/bin/env python3
# for ops/puppet CI: explicitly mark this file as python3 otherwise it defaults to py2

# SPDX-License-Identifier: Apache-2.0
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

from keystone.common import rbac_enforcer
from keystone.common import provider_api


from oslo_log import log as logging
from oslo_config import cfg
from oslo_messaging.notify import notifier

import designatemakedomain
from . import ldapgroups
from . import pageeditor

ENFORCER = rbac_enforcer.RBACEnforcer
PROVIDERS = provider_api.ProviderAPIs


LOG = logging.getLogger('nova.%s' % __name__)

wmfkeystone_opts = [
    cfg.StrOpt('admin_user',
               default='novaadmin',
               help='Admin service user for acceessing openstack endpoints'),
    cfg.StrOpt('admin_pass',
               default='',
               help='Admin password, used to authenticate with other services'),
    cfg.StrOpt('region',
               default='eqiad1-r',
               help='Openstack region (e.g. eqiad1-r'),
    cfg.StrOpt('auth_url',
               default='',
               help='Keystone URL, used to authenticate with other services'),
    cfg.StrOpt('user_role_name',
               default='reader',
               help='Name of simple project user role'),
    cfg.StrOpt('bastion_project_id',
               default='bastion',
               help='ID of bastion project needed for ssh access'),
    cfg.StrOpt('toolforge_project_id',
               default='tools',
               help='ID of toolforge project, no need for bastion add.'),
    cfg.StrOpt('wmcloud_domain_owner',
               default='cloudinfra',
               help='ID of toolforge project, no need for bastion add.'),
    cfg.StrOpt('ldap_rw_uri',
               default='',
               help='ldap server with read-write permissions'),
    cfg.StrOpt('ldap_base_dn',
               default='dc=wikimedia,dc=org',
               help='ldap dn for posix groups'),
    cfg.StrOpt('ldap_group_base_dn',
               default='ou=groups,dc=wikimedia,dc=org',
               help='ldap dn for posix groups'),
    cfg.StrOpt('ldap_user_base_dn',
               default='ou=people,dc=wikimedia,dc=org',
               help='ldap dn for user accounts'),
    cfg.StrOpt('ldap_project_base_dn',
               default='ou=projects,dc=wikimedia,dc=org',
               help='ldap dn for project records'),
    cfg.IntOpt('minimum_gid_number',
               default=40000,
               help='Starting gid number for posix groups'),
]

CONF = cfg.CONF
CONF.register_opts(wmfkeystone_opts, group='wmfhooks')


class KeystoneHooks(notifier.Driver):
    """Notifier class which handles extra project creation/deletion bits
    """
    def __init__(self, conf, topics, transport, version=1.0):
        self.page_editor = pageeditor.PageEditor()

    def _get_project_name_by_id(self, project_id):
        return PROVIDERS.resource_api.get_project(project_id)["name"]

    def _get_role_dict(self):
        rolelist = PROVIDERS.role_api.list_roles()
        roledict = {}
        # Make a dict to relate role names to ids
        for role in rolelist:
            roledict[role['name']] = role['id']

        return roledict

    def _get_current_assignments(self, project_id):
        reverseroledict = dict((v, k) for k, v in self._get_role_dict().items())

        rawassignments = PROVIDERS.assignment_api.list_role_assignments(project_id=project_id)
        assignments = {}
        for assignment in rawassignments:
            rolename = reverseroledict[assignment["role_id"]]
            if rolename not in assignments:
                assignments[rolename] = set()
            assignments[rolename].add(assignment["user_id"])
        return assignments

    # There are a bunch of different events which might update project membership,
    #  and the generic 'identity.projectupdated' comes in the wrong order.  So
    #  we're probably going to wind up getting called several times in quick succession,
    #  possible in overlapping invocations.  Watch out for race conditions!
    def _on_member_update(self, project_id, assignments=None):
        if not assignments:
            assignments = self._get_current_assignments(project_id)
        if assignments:
            ldapgroups.sync_ldap_project_group(project_id, assignments)
        else:
            ldapgroups.delete_ldap_project_group(project_id)

    def _add_to_bastion(self, roledict, user_id):
        # First make sure the user isn't already assigned to bastion
        assignments = self._get_current_assignments(CONF.wmfhooks.bastion_project_id)
        if user_id in assignments[CONF.wmfhooks.user_role_name]:
            LOG.debug("%s is already a member of %s" %
                      (user_id, CONF.wmfhooks.bastion_project_id))
            return

        LOG.debug("Adding %s to %s" % (user_id, CONF.wmfhooks.bastion_project_id))
        PROVIDERS.assignment_api.add_role_to_user_and_project(
            user_id,
            CONF.wmfhooks.bastion_project_id,
            roledict[CONF.wmfhooks.user_role_name])

    def _on_project_delete(self, project_id):
        project_name = self._get_project_name_by_id(project_id)
        LOG.warning("Beginning wmf hooks for project deletion: %s (%s)", project_id, project_name)

        ldapgroups.delete_ldap_project_group(project_id)
        self.page_editor.edit_page("", project_name, True)
        # Fixme: Replace this cleanup when we have a version of Designate
        #  that supports an all-projects flag
        # designatemakedomain.deleteDomain(
        #    CONF.wmfhooks.auth_url,
        #    CONF.wmfhooks.admin_user,
        #    CONF.wmfhooks.admin_pass,
        #    project_id,
        #    all=True,
        #    region=CONF.wmfhooks.region)

    def _create_project_page(self, project_id, project_name):
        # Create wikitech project page
        template_param_dict = {}
        template_param_dict['Resource Type'] = 'project'
        template_param_dict['Project ID'] = project_id
        template_param_dict['Project Name'] = project_name

        fields_string = ""
        for key in template_param_dict:
            fields_string += "\n|%s=%s" % (key, template_param_dict[key])

        self.page_editor.edit_page(fields_string, project_name, False,
                                   template='Nova Resource')

    def _on_project_create(self, project_id):
        project_name = self._get_project_name_by_id(project_id)
        LOG.warning("Beginning wmf hooks for project creation: %s (%s)", project_id, project_name)

        LOG.warning("Syncing membership with ldap for project %s" % project_id)
        assignments = self._get_current_assignments(project_id)
        if assignments:
            ldapgroups.sync_ldap_project_group(project_id, assignments)

        LOG.warning("Setting up default sudoers in ldap for project %s" % project_id)
        # Set up default sudoers in ldap
        ldapgroups.create_sudo_defaults(project_id)
        self._create_project_page(project_id, project_name)

        # This bit will take a while:
        if CONF.wmfhooks.region.endswith('-r'):
            deployment = CONF.wmfhooks.region[:-2]

            LOG.warning(
                "Creating default .wmcloud.org domain for project %s (%s)",
                project_name, project_id,
            )
            designatemakedomain.createDomain(
                CONF.wmfhooks.auth_url,
                CONF.wmfhooks.admin_user,
                CONF.wmfhooks.admin_pass,
                project_id,
                '{}.{}.wmcloud.org.'.format(project_name, deployment),
                CONF.wmfhooks.wmcloud_domain_owner,
                CONF.wmfhooks.region
            )

            LOG.warning(
                "Creating default svc.<project>.<deployment>.wikimedia.cloud for project %s (%s)",
                project_name, project_id
            )
            designatemakedomain.createDomain(
                CONF.wmfhooks.auth_url,
                CONF.wmfhooks.admin_user,
                CONF.wmfhooks.admin_pass,
                project_id,
                'svc.{}.{}.wikimedia.cloud.'.format(project_name, deployment),
                CONF.wmfhooks.wmcloud_domain_owner,
                CONF.wmfhooks.region
            )
        else:
            LOG.warning(
                "Unfamiliar region format; unable to create .wmcloud.org domain for %s (%s)",
                project_name, project_id
            )

        if CONF.wmfhooks.region == 'eqiad1-r':
            # Special case shortcut domains for eqiad1
            LOG.warning("Creating shortcut .wmcloud.org domain for project %s (%s) in eqiad1-r",
                        project_name, project_id)
            designatemakedomain.createDomain(
                CONF.wmfhooks.auth_url,
                CONF.wmfhooks.admin_user,
                CONF.wmfhooks.admin_pass,
                project_id,
                '{}.wmcloud.org.'.format(project_name),
                CONF.wmfhooks.wmcloud_domain_owner,
                CONF.wmfhooks.region
            )

        LOG.warning("Completed wmf hooks for project creation: %s" % project_id)

    def notify(self, context, message, priority, retry=False):
        event_type = message.get('event_type')

        if event_type == 'identity.project.deleted':
            self._on_project_delete(message['payload']['resource_info'])

        if event_type == 'identity.project.created':
            self._on_project_create(message['payload']['resource_info'])

        if event_type == 'identity.role_assignment.created':
            # Only update ldap for single-project role assignments
            if not message['payload']['inherited_to_projects']:
                project_id = message['payload']['project']
                role_id = message['payload']['role']
                self._on_member_update(project_id)
                if (project_id != CONF.wmfhooks.bastion_project_id
                        and project_id != CONF.wmfhooks.toolforge_project_id):
                    # If a user is added to a project, they will probably
                    #  want to ssh.  And for that, they will need to belong
                    #  to the bastion project.
                    # So, add them.  Note that this is a one-way trip; we don't
                    #  purge a user from bastion just because they've beeen
                    #  removed from every project.
                    roledict = self._get_role_dict()

                    # Only add users to bastion; other roles are
                    #  either assigned in addition to 'reader' or are
                    #  service roles that don't require ssh
                    if role_id == roledict[CONF.wmfhooks.user_role_name]:
                        user_id = message['payload']['user']
                        self._add_to_bastion(roledict, user_id)

        if event_type == 'identity.role_assignment.deleted':
            # Only update ldap for single-project role assignments
            if not message['payload']['inherited_to_projects']:
                project_id = message['payload']['project']
                assignments = self._get_current_assignments(project_id)
                self._on_member_update(project_id, assignments)
