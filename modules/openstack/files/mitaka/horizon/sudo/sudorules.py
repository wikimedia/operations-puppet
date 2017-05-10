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
import ldap.modlist
import logging
import requests

from django.conf import settings
from django.core.cache import cache
from django.utils.html import escape
from django.utils.safestring import mark_safe
from django.utils.translation import ugettext_lazy as _

from horizon import exceptions

logging.basicConfig()
LOG = logging.getLogger(__name__)


# A single sudoer rule, with some human readable labels
class SudoRule():
    def _get_formatted_user_list(self, userlist):
        projmembers = '%%project-%s' % self.project
        listcopy=list(userlist)
        if projmembers in listcopy:
           listcopy.remove(projmembers)
           listcopy.insert(0, "All project members") 

        if 'ALL' in listcopy:
           listcopy.remove('ALL')
           listcopy.insert(0, "All users") 

        return ', '.join(listcopy)


    def __init__(self,
                 project,
                 name,
                 users,
                 runas,
                 commands,
                 options):
        self.id = "%s-%s" % (project, name)
        self.project = project
        self.name = name
        self.users = users
        self.runas = runas
        self.commands = commands
        self.options = options

        self.users_hr = self._get_formatted_user_list(users)
        self.runas_hr = self._get_formatted_user_list(runas)

        self.commands_hr = ', '.join(commands)

        if '!authenticate' in self.options:
            self.authenticate = False
        else:
            self.authenticate = True

        options_copy = list(self.options)
        if '!authenticate' in options_copy:
            options_copy.remove('!authenticate')
        if 'authenticate' in options_copy:
            options_copy.remove('authenticate')
        self.options_hr = ', '.join(options_copy)


def _getLdapInfo(attr, conffile="/etc/ldap.conf"):
    try:
        f = open(conffile)
    except IOError:
        if conffile == "/etc/ldap.conf":
            # fallback to /etc/ldap/ldap.conf, which will likely
            # have less information
            f = open("/etc/ldap/ldap.conf")
    for line in f:
        if line.strip() == "":
            continue
        if line.split()[0].lower() == attr.lower():
            return line.split(None, 1)[1].strip()
            break


def _open_ldap():
    ldapHost = _getLdapInfo("uri")
    sslType = _getLdapInfo("ssl")

    binddn = "uid=%s,ou=people,dc=wikimedia,dc=org" % getattr(settings, "LDAP_USER_NAME", '')
    bindpw = getattr(settings, "LDAP_USER_PASSWORD", '')
    ds = ldap.initialize(ldapHost)
    ds.protocol_version = ldap.VERSION3
    if sslType == "start_tls":
        ds.start_tls_s()

    try:
        ds.simple_bind_s(binddn, bindpw)
        return ds
    except ldap.CONSTRAINT_VIOLATION:
        LOG.debug("LDAP bind failure:  Too many failed attempts.\n")
    except ldap.INVALID_DN_SYNTAX:
        LOG.debug("LDAP bind failure:  The bind DN is incorrect... \n")
    except ldap.NO_SUCH_OBJECT:
        LOG.debug("LDAP bind failure:  "
                  "Unable to locate the bind DN account.\n")
    except ldap.UNWILLING_TO_PERFORM as msg:
        LOG.debug("LDAP bind failure:  "
                  "The LDAP server was unwilling to perform the action"
                  " requested.\nError was: %s\n" % msg[0]["info"])
    except ldap.INVALID_CREDENTIALS:
        LOG.debug("LDAP bind failure:  Password incorrect.\n")

    return None


def rules_for_project(project):
    LOG.error("getting rules for %s" % project)
    projects_basedn = 'ou=projects,dc=wikimedia,dc=org'
    sudoer_base = "ou=sudoers,cn=%s,%s" % (project, projects_basedn)
    rules = []

    ds = _open_ldap()
    if not ds:
        LOG.error("Failed to connect to ldap; Leak a project group.")
        raise exceptions.ValidationError()

    sudorecords = ds.search_s(sudoer_base,
                              ldap.SCOPE_ONELEVEL,
                              filterstr='(objectClass=sudorole)')

    for record in sudorecords:
        content = record[1]
        LOG.warning("content: %s" % content)
        LOG.warning("content keys: %s" % content.keys())
        LOG.warning("cn is: %s" % content['cn'])

        name = content.get('cn', [''])[0]
        LOG.warning("name is: %s" % name)
        users = content.get("sudoUser", [])
        runas = content.get("sudoRunAsUser", [])
        command = content.get("sudoCommand", [])
        options = content.get("sudoOption", [])

        if len(content['sudoCommand']) > 1:
            LOG.error("Multiple commands in %s!" % record[0])

        if 'sudoOption' in content:
            if len(content['sudoOption']) > 1:
                LOG.error("Multiple options in %s!" % record[0])

        rule = SudoRule(project,
                        name,
                        users,
                        runas,
                        command,
                        options)
        rules.append(rule)

    LOG.warning("Rules: %s" % rules)
    return rules
