# Copyright (c) 2017 Andrew Bogott for Wikimedia Foundation
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

import ldap
import logging

from django.utils.translation import ugettext_lazy as _

from horizon import exceptions
from horizon import forms
from horizon import workflows

from openstack_dashboard.api import keystone

import sudorules

LOG = logging.getLogger(__name__)

SUDO_USER_MEMBER_SLUG = 'sudo_users'
SUDO_RUNAS_SLUG = 'sudo_runas'
COMMON_HORIZONTAL_TEMPLATE = "project/sudo/_common_horizontal_form.html"

SUDO_USER_ROLE_NAME = 'user'
SUDO_RUNAS_ROLE_NAME = 'runas'

NO_SUDO_FOR = ['novaadmin', 'novaobserver']


def allUsersTuple(project_id):
    return ("%%project-%s" % project_id, "*Any project member*")


def anyUserTuple():
    return ("ALL", "*Anyone*")


class UpdateRuleUsersAction(workflows.MembershipAction):
    role_name = SUDO_USER_ROLE_NAME

    def __init__(self, request, *args, **kwargs):
        super(UpdateRuleUsersAction, self).__init__(request,
                                                    *args,
                                                    **kwargs)
        err_msg = _('Unable to retrieve user list. Please try again later.')

        project_id = self.initial['project_id']

        # The user-selection widget we're using thinks in terms of roles.  We only want
        #  one, simple list so we will collect them in the stand-in 'user' role.
        default_role_name = self.get_default_role_field_name()
        self.fields[default_role_name] = forms.CharField(required=False)
        self.fields[default_role_name].initial = self.role_name

        # Get list of available users
        all_users = []
        try:
            # We can't use the default user_list function because it requires
            #  us to be an admin user.
            users = keystone.keystoneclient(request).users.list(default_project=project_id)
            all_users = [keystone.VERSIONS.upgrade_v2_user(user) for user in users]
            all_users_dict = {user.id: user for user in all_users}
        except Exception:
            exceptions.handle(request, err_msg)

        # The v3 user list doesn't actually filter by project (code comments
        #  to the contrary) so we have to dig through the role list to find
        #  out who's actually in our project.
        # Anyone who is in all_users_dict and also has a role in the
        #  project is a potential sudoer.
        project_users = set()
        manager = keystone.keystoneclient(request).role_assignments
        project_role_assignments = manager.list(project=project_id)
        for role_assignment in project_role_assignments:
            if not hasattr(role_assignment, 'user'):
                continue
            user_id = role_assignment.user['id']
            if user_id in NO_SUDO_FOR:
                continue
            if user_id in all_users_dict:
                project_users.add(all_users_dict[user_id])

        users_list = [(user.id, user.name) for user in project_users]
        users_list.insert(0, anyUserTuple())
        users_list.insert(0, allUsersTuple(project_id))

        # Add a field to collect the list of users with role 'user'
        field_name = self.get_member_field_name(self.role_name)
        label = self.role_name
        self.fields[field_name] = forms.MultipleChoiceField(required=False,
                                                            label=label)
        self.fields[field_name].choices = users_list
        self.fields[field_name].initial = self.initial[self.role_name]

    class Meta(object):
        name = _("Users")
        slug = SUDO_USER_MEMBER_SLUG


class UpdateRuleUsers(workflows.UpdateMembersStep):
    action_class = UpdateRuleUsersAction
    available_list_title = _("")
    members_list_title = _("Rule Users")
    no_available_text = _("No users found.")
    no_members_text = _("No users.")
    show_roles = False
    role_name = SUDO_USER_ROLE_NAME
    contributes = (SUDO_USER_ROLE_NAME,)

    def contribute(self, data, context):
        if data:
            post = self.workflow.request.POST

            field_name = self.get_member_field_name(self.role_name)
            context[self.role_name] = post.getlist(field_name)
        return context


class UpdateRuleRunAsUsersAction(UpdateRuleUsersAction):
    role_name = SUDO_RUNAS_ROLE_NAME

    class Meta(object):
        name = _("Run as")
        slug = SUDO_RUNAS_SLUG


class UpdateRuleRunAsUsers(UpdateRuleUsers):
    action_class = UpdateRuleRunAsUsersAction
    available_list_title = _("")
    members_list_title = _("Allow running as")
    role_name = SUDO_RUNAS_ROLE_NAME
    contributes = (SUDO_RUNAS_ROLE_NAME,)


LDAP_TEXT_VALIDATOR = "^[A-Za-z][\w_\-\.]*$"
LDAP_TEXT_VALIDATOR_MESSAGES = {'invalid':
                                _("This must start with a letter, "
                                  "followed by only letters, numbers, ., -, or _.")}


class CreateRuleInfoAction(workflows.Action):
    # Hide the domain_id and domain_name by default
    project_id = forms.CharField(label=_("Project ID"),
                                 required=False,
                                 widget=forms.HiddenInput())
    rulename = forms.RegexField(label=_("Rule Name"),
                                max_length=64,
                                help_text=_("Name of this sudo rule. "
                                            "Must be a unique name within this project."),
                                regex=LDAP_TEXT_VALIDATOR,
                                error_messages=LDAP_TEXT_VALIDATOR_MESSAGES,
                                required=True)
    commands = forms.CharField(widget=forms.widgets.Textarea(
                               attrs={'rows': 4}),
                               label=_("Commands"),
                               help_text=_("List of permitted commands, one per line, "
                                           "or ALL to permit all actions."),
                               required=True)
    options = forms.CharField(widget=forms.widgets.Textarea(
                              attrs={'rows': 2}),
                              label=_("Options"),
                              required=False)
    authrequired = forms.BooleanField(label=_("Passphrase required"),
                                      required=False,
                                      initial=False)

    def __init__(self, request, *args, **kwargs):
        super(CreateRuleInfoAction, self).__init__(request,
                                                   *args,
                                                   **kwargs)

    class Meta(object):
        name = _("Rule")
        help_text = _("Create a rule to permit certain sudo commands.")
        slug = "rule_info"


class ModifyRuleInfoAction(CreateRuleInfoAction):
    def __init__(self, request, *args, **kwargs):
        super(ModifyRuleInfoAction, self).__init__(request,
                                                   *args,
                                                   **kwargs)
        self.fields['rulename'].widget.attrs['readonly'] = True

    class Meta(object):
        name = _("Rule")
        help_text = _("Update a sudo rule.")
        slug = "modify_rule_info"


class CreateRuleInfo(workflows.Step):
    action_class = CreateRuleInfoAction
    template_name = COMMON_HORIZONTAL_TEMPLATE
    contributes = ("rulename",
                   "commands",
                   "project_id",
                   "options",
                   "authrequired")

    def contribute(self, data, context):
        if data:
            post = self.workflow.request.POST

            context['commands'] = post.getlist('commands')[0].splitlines()
            context['options'] = post.getlist('options')[0].splitlines()
            if not post.getlist('authrequired'):
                context['options'].append("!authenticate")
            context['rulename'] = post.getlist('rulename')[0]

        return context


class ModifyRuleInfo(CreateRuleInfo):
    action_class = ModifyRuleInfoAction


class CreateRule(workflows.Workflow):
    slug = "create_sudo_rule"
    name = _("Create Rule")
    finalize_button_name = _("Create Rule")
    success_message = _('Created sudo rule "%s".')
    failure_message = _('Unable to create sudo rule.')
    success_url = "horizon:project:sudo:index"
    default_steps = (CreateRuleInfo,
                     UpdateRuleUsers,
                     UpdateRuleRunAsUsers)

    def __init__(self, request=None, context_seed=None, entry_point=None,
                 *args, **kwargs):
        super(CreateRule, self).__init__(request=request,
                                         context_seed=context_seed,
                                         entry_point=entry_point,
                                         *args,
                                         **kwargs)

    def handle(self, request, data):
        rule = sudorules.SudoRule(project=data['project_id'],
                                  name=data['rulename'],
                                  users=data[SUDO_USER_ROLE_NAME],
                                  runas=data[SUDO_RUNAS_ROLE_NAME],
                                  commands=data['commands'],
                                  options=data['options'])

        try:
            sudorules.add_rule(rule)
        except ldap.ALREADY_EXISTS:
            exceptions.handle(request, _("A rule named %s already exists.") % data['rulename'])
            return False

        return True


class ModifyRule(workflows.Workflow):
    slug = "modify_sudo_rule"
    name = _("Modify Rule")
    finalize_button_name = _("Update Rule")
    success_message = _('Changed sudo rule "%s".')
    failure_message = _('Unable to change sudo rule "%s".')
    success_url = "horizon:project:sudo:index"
    default_steps = (ModifyRuleInfo,
                     UpdateRuleUsers,
                     UpdateRuleRunAsUsers)

    def __init__(self, request=None, context_seed=None, entry_point=None,
                 *args, **kwargs):
        super(ModifyRule, self).__init__(request=request,
                                         context_seed=context_seed,
                                         entry_point=entry_point,
                                         *args,
                                         **kwargs)

    def handle(self, request, data):
        rule = sudorules.SudoRule(project=data['project_id'],
                                  name=data['rulename'],
                                  users=data[SUDO_USER_ROLE_NAME],
                                  runas=data[SUDO_RUNAS_ROLE_NAME],
                                  commands=data['commands'],
                                  options=data['options'])

        return sudorules.update_rule(rule)
