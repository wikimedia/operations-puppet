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
import ldap
import ldap.modlist

from keystone import exception

from oslo_log import log as logging
from oslo_config import cfg

LOG = logging.getLogger('nova.%s' % __name__)


def _open_ldap():
    ldapHost = cfg.CONF.wmfhooks.ldap_rw_uri
    binddn = cfg.CONF.ldap.user
    bindpw = cfg.CONF.ldap.password
    ds = ldap.initialize(ldapHost)
    ds.protocol_version = ldap.VERSION3
    ds.start_tls_s()

    try:
        ds.simple_bind_s(binddn, bindpw)
        return ds
    except ldap.CONSTRAINT_VIOLATION:
        LOG.warning("LDAP bind failure:  Too many failed attempts.\n")
    except ldap.INVALID_DN_SYNTAX:
        LOG.warning("LDAP bind failure:  The bind DN is incorrect... \n")
    except ldap.NO_SUCH_OBJECT:
        LOG.warning("LDAP bind failure:  "
                    "Unable to locate the bind DN account.\n")
    except ldap.UNWILLING_TO_PERFORM as msg:
        LOG.warning("LDAP bind failure:  "
                    "The LDAP server was unwilling to perform the action"
                    " requested.\nError was: %s\n" % msg[0]["info"])
    except ldap.INVALID_CREDENTIALS:
        LOG.warning("LDAP bind failure:  Password incorrect.\n")

    return None


# ds is presumed to be an already-open ldap connection
def _get_next_gid_number(ds):
    basedn = cfg.CONF.wmfhooks.ldap_base_dn
    allrecords = ds.search_s(basedn,
                             ldap.SCOPE_SUBTREE,
                             filterstr='(objectClass=posixGroup)',
                             attrlist=['gidNumber'])

    highest = cfg.CONF.wmfhooks.minimum_gid_number
    for record in allrecords:
        if 'gidNumber' in record[1]:
            number = int(record[1]['gidNumber'][0])
            if number > highest:
                highest = number

    # Fixme:  Check against a hard max gid number limit?
    return highest + 1


# ds should be an already-open ldap connection.
#
# groupname is the name of the group to create, probably project-<projectname>
def _get_ldap_group(ds, groupname):
    basedn = cfg.CONF.wmfhooks.ldap_group_base_dn
    searchdn = "cn=%s,%s" % (groupname, basedn)
    try:
        thisgroup = ds.search_s(searchdn, ldap.SCOPE_BASE)
        return thisgroup
    except ldap.LDAPError:
        return None


def delete_ldap_project_group(project_id):
    basedn = cfg.CONF.wmfhooks.ldap_group_base_dn
    groupname = "project-%s" % project_id
    dn = "cn=%s,%s" % (groupname, basedn)

    ds = _open_ldap()
    if not ds:
        LOG.error("Failed to connect to ldap; Leak a project group.")
        raise exception.ValidationError(message='Failed to connect to ldap; Leak a project group.')

    try:
        ds.delete_s(dn)
    except ldap.LDAPError as e:
        LOG.warning("Failed to delete %s from ldap: %s" % (dn, e))

    # delete everything under the project subtree
    basedn = cfg.CONF.wmfhooks.ldap_project_base_dn
    projectbase = "cn=%s,%s" % (project_id, basedn)

    try:
        search = ds.search_s(projectbase, ldap.SCOPE_SUBTREE)
    except ldap.NO_SUCH_OBJECT:
        LOG.info("Unable to clean up %s; dn not found." % projectbase)
        return

    delete_list = [record for record, _ in search]
    delete_list.reverse()
    for record in delete_list:
        try:
            ds.delete_s(record)
        except ldap.LDAPError as e:
            LOG.warning("Failed to delete %s from ldap" % (record, e))


def sync_ldap_project_group(project_id, keystone_assignments):
    groupname = "project-%s" % project_id
    LOG.info("Syncing keystone project membership with ldap group %s"
             % groupname)
    ds = _open_ldap()
    if not ds:
        LOG.error("Failed to connect to ldap; cannot set up new project.")
        raise exception.ValidationError(message='Failed to connect to ldap; '
                                        'cannot set up new project.')

    allusers = set()
    for key in keystone_assignments:
        allusers |= set(keystone_assignments[key])

    if 'novaobserver' in allusers:
        allusers.remove('novaobserver')

    basedn = cfg.CONF.wmfhooks.ldap_user_base_dn
    members_as_bytes = [
        ("uid=%s,%s" % (user, basedn)).encode('utf-8')
        for user in allusers
    ]

    basedn = cfg.CONF.wmfhooks.ldap_group_base_dn
    dn = "cn=%s,%s" % (groupname, basedn)

    existingEntry = _get_ldap_group(ds, groupname)
    if existingEntry:
        # We're modifying an existing group
        oldEntry = existingEntry[0][1]
        newEntry = oldEntry.copy()
        newEntry['member'] = members_as_bytes

        modlist = ldap.modlist.modifyModlist(oldEntry, newEntry)
        if modlist:
            ds.modify_s(dn, modlist)
    else:
        # We're creating a new group from scratch.
        #  There is a potential race between _get_next_git_number()
        #  and ds.add_s, so we make a few attempts.
        #  around this function.
        groupEntry = {}
        groupEntry['member'] = members_as_bytes
        groupEntry['objectClass'] = [b'groupOfNames', b'posixGroup', b'top']
        groupEntry['cn'] = [groupname.encode('utf-8')]
        for i in range(0, 4):
            groupEntry['gidNumber'] = [str(_get_next_gid_number(ds)).encode('utf-8')]
            modlist = ldap.modlist.addModlist(groupEntry)
            try:
                ds.add_s(dn, modlist)
                break
            except ldap.LDAPError as exc:
                LOG.warning("Failed to create group %s, attempt number %s: %s %s" %
                            (dn, i, exc, modlist))


def create_sudo_defaults(project_id):
    ds = _open_ldap()
    if not ds:
        LOG.error("Failed to connect to ldap; Unable to create sudo rules.")
        raise exception.ValidationError(message='Failed to connect to ldap; '
                                        'Unable to create sudo rules.')

    userbasedn = cfg.CONF.wmfhooks.ldap_user_base_dn
    basedn = cfg.CONF.wmfhooks.ldap_project_base_dn
    projectbase = "cn=%s,%s" % (project_id, basedn)
    # We may or may not already have one of these... if it fails just move on.
    projectEntry = {}
    projectEntry['objectClass'] = [b'extensibleobject', b'groupofnames', b'top']
    projectEntry['member'] = [("uid=%s,%s" %
                              (cfg.CONF.wmfhooks.admin_user, userbasedn)).encode('utf-8')]
    modlist = ldap.modlist.addModlist(projectEntry)
    try:
        ds.add_s(projectbase, modlist)
    except ldap.LDAPError as e:
        LOG.warning("Failed to create project base %s in ldap: %s" % (projectbase, e))

    # this record is empty and arbitrary, but keeps sudo-ldap from
    #  freaking out and ignoring all groups.
    groupsdn = "ou=groups,%s" % projectbase
    groupsentry = {}
    groupsentry['objectClass'] = [b'organizationalUnit']
    modlist = ldap.modlist.addModlist(groupsentry)
    try:
        ds.add_s(groupsdn, modlist)
    except ldap.LDAPError as e:
        LOG.warning("Failed to create base group entry: %s" % e)

    #  This one too!
    peopledn = "ou=people,%s" % projectbase
    peopleentry = {}
    peopleentry['objectClass'] = [b'organizationalUnit']
    modlist = ldap.modlist.addModlist(peopleentry)
    try:
        ds.add_s(peopledn, modlist)
    except ldap.LDAPError as e:
        LOG.warning("Failed to create base people entry: %s" % e)

    sudoerbase = "ou=sudoers,%s" % projectbase
    sudoEntry = {}
    sudoEntry['objectClass'] = [b'organizationalUnit', b'top']
    modlist = ldap.modlist.addModlist(sudoEntry)
    try:
        ds.add_s(sudoerbase, modlist)
    except ldap.LDAPError as e:
        LOG.warning("Failed to create base sudoer group: %s" % e)

    sudoEntry = {}
    defaultdn = "cn=default-sudo,%s" % sudoerbase
    sudoEntry['objectClass'] = [b'sudoRole']
    sudoEntry['sudoUser'] = [('%%project-%s' % project_id).encode('utf-8')]
    sudoEntry['sudoCommand'] = [b'ALL']
    sudoEntry['sudoOption'] = [b'!authenticate']
    sudoEntry['sudoHost'] = [b'ALL']
    sudoEntry['cn'] = [b'default-sudo']
    modlist = ldap.modlist.addModlist(sudoEntry)
    try:
        ds.add_s(defaultdn, modlist)
    except ldap.LDAPError as e:
        LOG.warning("Failed to create default sudoer entry: %s" % e)

    defaultasdn = "cn=default-sudo-as,%s" % sudoerbase
    # The runas entry is the same as the default entry, plus one field
    sudoEntry['sudoRunAsUser'] = [("%%project-%s" % project_id).encode('utf-8')]
    sudoEntry['cn'] = [b'default-sudo-as']
    modlist = ldap.modlist.addModlist(sudoEntry)
    try:
        ds.add_s(defaultasdn, modlist)
    except ldap.LDAPError as e:
        LOG.warning("Failed to create default sudo-as entry: %s" % e)
