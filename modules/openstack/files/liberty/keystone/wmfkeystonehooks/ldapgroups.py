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

    binddn = cfg.CONF.ldap.user
    bindpw = cfg.CONF.ldap.password
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


# ds is presumed to be an already-open ldap connection
def _all_groups(ds):
    basedn = "ou=groups,dc=wikimedia,dc=org"
    allgroups = ds.search_s(basedn, ldap.SCOPE_ONELEVEL)
    return allgroups


# ds is presumed to be an already-open ldap connection
def _get_next_gid_number(ds):
    highest = 40000
    for group in _all_groups(ds):
        if 'gidNumber' in group[1]:
            number = int(group[1]['gidNumber'][0])
            if number > highest:
                highest = number

    # Fixme:  Check against a hard max gid number limit?
    return highest + 1


def _get_ldap_group(ds, groupname):
    searchdn = "cn=%s,ou=groups,dc=wikimedia,dc=org" % groupname
    try:
        thisgroup = ds.search_s(searchdn, ldap.SCOPE_BASE)
        return thisgroup
    except ldap.LDAPError:
        return None


def _sync_ldap_project_group(project_id, keystone_assignments):
    groupname = "project-%s" % project_id.encode('utf-8')
    LOG.info("Syncing keystone project membership with ldap group %s"
             % groupname)
    ds = _open_ldap()
    if not ds:
        LOG.error("Failed to connect to ldap; cannot set up new project.")
        raise exception.ValidationError()

    allusers = set()
    for key in keystone_assignments:
        allusers |= set(keystone_assignments[key])

    if 'novaobserver' in allusers:
        allusers.remove('novaobserver')

    members = ["uid=%s,ou=people,dc=wikimedia,dc=org" % user.encode('utf-8')
               for user in allusers]

    dn = "cn=%s,ou=groups,dc=wikimedia,dc=org" % groupname

    existingEntry = _get_ldap_group(ds, groupname)
    if existingEntry:
        # We're modifying an existing group
        oldEntry = existingEntry[0][1]
        newEntry = oldEntry.copy()
        newEntry['member'] = members

        modlist = ldap.modlist.modifyModlist(oldEntry, newEntry)
        if modlist:
            ds.modify_s(dn, modlist)
    else:
        # We're creating a new group from scratch.
        #  This is a potential race; maybe we should have a lock
        #  around this function.
        groupEntry = {}
        groupEntry['member'] = members
        groupEntry['gidNumber'] = [str(_get_next_gid_number(ds))]
        groupEntry['objectClass'] = ['groupOfNames', 'posixGroup', 'top']
        groupEntry['cn'] = [groupname]
        modlist = ldap.modlist.addModlist(groupEntry)
        ds.add_s(dn, modlist)
