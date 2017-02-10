#!/usr/bin/env python
#
# Copyright (c) 2017 Wikimedia Foundation, Inc.
#

import yaml
import ldap
import datetime
import tempfile
import subprocess
import os
import shutil


def print_error(user, reason):
    print "Invalid entry for", user, ";", reason


def get_ldap_group_members(group_name):
    ldap_conn = ldap.initialize('ldaps://ldap-labs.eqiad.wikimedia.org:636')
    ldap_conn.protocol_version = ldap.VERSION3

    members = []
    ldapdata = ldap_conn.search_s(
        "ou=groups,dc=wikimedia,dc=org",
        ldap.SCOPE_SUBTREE,
        "(&(objectclass=groupOfNames)(cn=" + group_name + "))",
        attrlist=['member'],
    )

    for member_dn in ldapdata[0][1]['member']:
        members.append(member_dn.split(",")[0].split("=")[1])

    return members


def main():
    tmp_dir = tempfile.mkdtemp()
    os.chdir(tmp_dir)
    try:
        subprocess.check_output(["git", "clone",
                                 "http://gerrit.wikimedia.org/r/p/operations/puppet.git"],
                                stderr=subprocess.STDOUT, shell=False)
    except subprocess.CalledProcessError, e:
        print "git checkout failed", e.returncode

    users = {}
    data = open('puppet/modules/admin/data/data.yaml', 'r')
    yamldata = yaml.safe_load(data)
    data.close()
    shutil.rmtree(tmp_dir)

    absented_users = yamldata['groups']['absent']['members']
    for table in ['users', 'ldap_only_users']:
        for username, userdata in yamldata[table].items():
            if userdata['ensure'] == 'absent':
                if username not in absented_users:
                    print username, "is absent, but missing in absent group"
                continue

            groups = []
            for group, groupdata in yamldata['groups'].items():
                if username in groupdata['members']:
                    groups.append(group)

            if table == 'users':
                users[username] = {
                    'realname': userdata['realname'],
                    'ldap_only': False,
                    'uid': userdata['uid'],
                    'prod_groups': groups,
                    'has_server_access': (len(userdata['ssh_keys']) > 0),
                }
            elif table == 'ldap_only_users':
                users[username] = {
                    'realname': userdata['realname'],
                    'ldap_only': True,
                }

            if userdata.get('email', None) is None:
                print_error(username, "has no email address specified in data.yaml")
            else:
                users[username]['email'] = userdata.get('email', None)

            if userdata.get('expiry_date', None):
                users[username]['expiry_date'] = userdata.get('expiry_date', None)
                if userdata.get('expiry_contact', None):
                    users[username]['expiry_contact'] = userdata.get('expiry_contact', None)
                else:
                    print_error(username, "has an expiry date, but no contact address")

    known_users = users.keys()

    for group, groupdata in yamldata['groups'].items():
        if group == "absent":
            continue
        for member in groupdata['members']:
            if member not in known_users:
                print "Group", group, "has a member not specified in the users section:", member

    ldap_ops = get_ldap_group_members('ops')
    yml_ops = yamldata['groups']['ops']['members'] + yamldata['groups']['datacenter-ops']['members']
    if sorted(ldap_ops) != sorted(yml_ops):
        print "Membership of ops group in LDAP and YAML (consisting of ops "
        "and datacenter-ops) is not identical"

    for group in ['ops', 'wmf', 'nda']:
        ldap_members = get_ldap_group_members(group)

        for i in ldap_members:
            if i not in known_users:
                print i, "in privileged LDAP group (", group, ") but not present in data.yaml"

    a = set(get_ldap_group_members('wmf'))
    b = set(get_ldap_group_members('nda'))
    if len(a & b) > 0:
        for duplicated_user in set(a & b):
            print duplicated_user, "is present in both 'wmf' and 'nda' group"

    current_date = datetime.datetime.now()
    for i in users.keys():
        attrs = users[i]
        if 'expiry_date' in attrs.keys():
            expiry = datetime.datetime.strptime(str(attrs['expiry_date']), "%Y-%m-%d")
            delta = expiry - current_date

            if delta.days <= 14:
                print "The NDA/MOU for", i, "has will lapse in", delta.days, "days."
                print "  Please get in touch with", attrs['expiry_contact']

        if 'ldap_only' in attrs.keys() and not attrs['ldap_only']:
            if "ops" in attrs['prod_groups']:
                if len(attrs['prod_groups']) < 2:
                    print_error(i, "malformed membership for ops user, needs at "
                                "least 'gitpuppet' and 'ops'")
                elif len(attrs['prod_groups']) > 2:
                    # ops and gitpuppet are default for all ops users
                    # analytics-privatedata-users enables mysql access in addition to
                    #    cluster-wide root permissions, so might be used in addition to ops privs
                    # researchers enables mysql access in addition to cluster-wide root permissions,
                    #    so might be used in addition to ops privs
                    # statistics-privatedata-users enables mysql access as well
                    # deploy-phabricator concerns handling of keyholder for deployment
                    # analytics-search-users concerns user creation in HDFS
                    for j in ['gitpuppet', 'ops', 'researchers', 'statistics-privatedata-users',
                              'analytics-privatedata-users', 'deploy-phabricator',
                              'analytics-search-users']:
                        if attrs['prod_groups'].count(j) > 0:
                            attrs['prod_groups'].remove(j)
                    if len(attrs['prod_groups']) > 0:
                        print_error(i, "malformed membership for ops user, has additional group "
                                    "memberships other than 'gerritpuppet' and 'ops':")
                        print "  ", attrs['prod_groups']


if __name__ == '__main__':
    main()
