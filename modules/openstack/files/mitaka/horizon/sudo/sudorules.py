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

from django.conf import settings

from horizon import exceptions

logging.basicConfig()
LOG = logging.getLogger(__name__)


# A single sudoer rule, with some human readable labels
class SudoRule():
    def _get_formatted_user_list(self, userlist):
        projmembers = '%%project-%s' % self.project
        listcopy = list(userlist)
        if projmembers in listcopy:
            listcopy.remove(projmembers)
            listcopy.insert(0, "Any project member")

        if 'ALL' in listcopy:
            listcopy.remove('ALL')
            listcopy.insert(0, "Anyone")

        return ', '.join(listcopy)

    def __init__(self,
                 project,
                 name,
                 users,
                 runas,
                 commands,
                 options):
        self.id = name
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
            self.authrequired = False
        else:
            self.authrequired = True

        if '!authenticate' in options:
            options.remove('!authenticate')
        if 'authenticate' in options:
            options.remove('authenticate')

        self.options_hr = ', '.join(options)


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

    binddn = getattr(settings, "LDAP_USER", '')
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


def rules_for_project(project, rulename=None):
    LOG.debug("getting rules for %s" % project)
    projects_basedn = getattr(settings, "LDAP_PROJECTS_BASE", '')
    sudoer_base = "ou=sudoers,cn=%s,%s" % (project, projects_basedn)
    rules = []

    ds = _open_ldap()
    if not ds:
        LOG.error("Failed to connect to ldap.")
        raise exceptions.ValidationError()

    if rulename:
        filter = "(&(objectClass=sudorole)(cn=%s))" % rulename
    else:
        filter = '(objectClass=sudorole)'

    sudorecords = ds.search_s(sudoer_base,
                              ldap.SCOPE_ONELEVEL,
                              filterstr=filter)

    for record in sudorecords:
        content = record[1]

        name = content.get('cn', [''])[0]
        users = content.get("sudoUser", [])
        runas = content.get("sudoRunAsUser", [])
        command = content.get("sudoCommand", [])
        options = content.get("sudoOption", [])

        rule = SudoRule(project,
                        name,
                        users,
                        runas,
                        command,
                        options)
        rules.append(rule)

    return rules


def _dn_for_rule(rule):
    projects_basedn = getattr(settings, "LDAP_PROJECTS_BASE", '')
    sudoer_base = "ou=sudoers,cn=%s,%s" % (rule.project, projects_basedn)
    return "cn=%s,%s" % (rule.name, sudoer_base)


def _modentry_for_rule(rule):
    ruleEntry = {}
    ruleEntry['cn'] = rule.name.encode('utf8')
    ruleEntry['objectClass'] = 'sudoRole'
    ruleEntry['sudoHost'] = 'ALL'
    ruleEntry['sudoOption'] = [opt.encode('utf8') for opt in rule.options]
    ruleEntry['sudoCommand'] = [cmd.encode('utf8') for cmd in rule.commands]
    ruleEntry['sudoUser'] = [usr.encode('utf8') for usr in rule.users]
    ruleEntry['sudoRunAsUser'] = [usr.encode('utf8') for usr in rule.runas]

    if not rule.authrequired:
        ruleEntry['sudoOption'].append("!authenticate")

    return ruleEntry


def add_rule(rule):
    ds = _open_ldap()
    if not ds:
        LOG.error("Failed to connect to ldap.")
        raise exceptions.ValidationError()

    dn = _dn_for_rule(rule)
    modentry = _modentry_for_rule(rule)
    modlist = ldap.modlist.addModlist(modentry)
    ds.add_s(dn, modlist)
    return True


def update_rule(rule):
    ds = _open_ldap()
    if not ds:
        LOG.error("Failed to connect to ldap.")
        raise exceptions.ValidationError()

    dn = _dn_for_rule(rule)
    newentry = _modentry_for_rule(rule)

    # get the old rule so we can make a proper modlist.  This is potentially
    #  racy but less racy than caching it elsewhere.
    oldrecords = ds.search_s(dn, ldap.SCOPE_BASE)

    modlist = ldap.modlist.modifyModlist(oldrecords[0][1], newentry)
    ds.modify_s(dn, modlist)
    return True


def delete_rule(project, rulename):
    ds = _open_ldap()
    if not ds:
        LOG.error("Failed to connect to ldap.")
        raise exceptions.ValidationError()

    projects_basedn = getattr(settings, "LDAP_PROJECTS_BASE", '')
    sudoer_base = "ou=sudoers,cn=%s,%s" % (project, projects_basedn)

    dn = "cn=%s,%s" % (rulename, sudoer_base)
    ds.delete_s(dn)
    return True
