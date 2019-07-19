#!/usr/bin/env python
#
# Copyright (c) 2018 Wikimedia Foundation, Inc.

import yaml
import ldap
import datetime
import tempfile
import subprocess
import os
import shutil
import sys

LDAP_SERVER_URI = "ldaps://ldap-ro.eqiad.wikimedia.org:636"


def flatten(l, a=None):
    '''
    Flatten a list recursively. Make sure to only flatten list elements, which
    is a problem with itertools.chain which also flattens strings. a defaults
    to None instead of the empty list to avoid issues with Copy by reference
    which is the default in python
    '''

    if a is None:
        a = []

    for i in l:
        if isinstance(i, list):
            flatten(i, a)
        else:
            a.append(i)
    return a


def get_ldap_group_members(group_name):
    ldap_conn = ldap.initialize(LDAP_SERVER_URI)
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


def fetch_yaml_data():
    tmp_dir = tempfile.mkdtemp()
    os.chdir(tmp_dir)
    try:
        subprocess.check_output(["git", "clone",
                                 "https://gerrit.wikimedia.org/r/operations/puppet.git"],
                                stderr=subprocess.STDOUT, shell=False)
    except subprocess.CalledProcessError as e:
        print "git checkout failed", e.returncode
        shutil.rmtree(tmp_dir)
        sys.exit(1)

    with open('puppet/modules/admin/data/data.yaml', 'r') as data:
        yamldata = yaml.safe_load(data)
    shutil.rmtree(tmp_dir)
    return yamldata


def validate_absented_users(yamldata):
    log = ""
    absented_users = yamldata['groups']['absent']['members']
    absented_users += yamldata['groups']['absent_ldap']['members']
    for table in ['users', 'ldap_only_users']:
        for username, userdata in yamldata[table].items():
            if userdata['ensure'] == 'absent':
                if username not in absented_users:
                    log += username + " is absent, but missing in absent groups\n"
    return log


def parse_users(yamldata):
    users = {}

    for table in ['users', 'ldap_only_users']:
        for username, userdata in yamldata[table].items():
            if userdata['ensure'] == 'absent':
                continue

            groups = []
            for group, groupdata in yamldata['groups'].items():
                if username in flatten(groupdata['members']):
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
                users[username]['email'] = 'undefined'
            else:
                users[username]['email'] = userdata.get('email', None)

            if userdata.get('expiry_date', None):
                users[username]['expiry_date'] = userdata.get('expiry_date', None)
                if userdata.get('expiry_contact', None):
                    users[username]['expiry_contact'] = userdata.get('expiry_contact', None)
                else:
                    users[username]['expiry_contact'] = 'undefined'

    return users


# Every account needs an email address
def validate_email_addresses(users):
    log = ""
    for i in users.keys():
        attrs = users[i]
        if attrs['email'] == 'undefined':
            log += i + " has no email address specified in data.yaml\n"
    return log


# Every time-limited account needs an expiry date
def validate_expiry_contacts(users):
    log = ""
    for i in users.keys():
        attrs = users[i]
        if 'expiry_contact' in attrs and attrs['expiry_contact'] == 'undefined':
            log += i + " has an expiry date, but no contact address\n"
    return log


# Every account should only be in wmf or nda group, not both
def validate_mutually_exclusive_privileged_ldap_groups():
    log = ""
    ops_members = set(get_ldap_group_members('wmf'))
    ldap_members = set(get_ldap_group_members('nda'))
    if len(ops_members & ldap_members) > 0:
        for duplicated_user in set(ops_members & ldap_members):
            log += duplicated_user + " is present in both 'wmf' and 'nda' group\n"
    return log


# Every account in the LDAP ops should be in either the ops or datacenter-ops YAML group
def validate_common_ops_group(yamldata):
    ldap_ops = get_ldap_group_members('ops')
    yml_ops = yamldata['groups']['ops']['members'] + yamldata['groups']['datacenter-ops']['members']
    if sorted(ldap_ops) != sorted(yml_ops):
        ops_diff = list(set(sorted(ldap_ops)) - set(sorted(yml_ops)))
        return "Membership of ops group in LDAP and YAML are not identical: " + str(ops_diff)
    else:
        return ""


# Every account in the wmf group should be registered in data.yaml with a wikimedia.org address
# Google account and every member in the nda group with a non-wikimedia.org address
def validate_privileged_ldap_groups_memberships(users):
    log = ""

    for member in get_ldap_group_members('wmf'):
        if member in users.keys():  # flagged via different account check
            if 'email' in users[member].keys():
                if not users[member]['email'].endswith('wikimedia.org'):
                    log += member + " is in wmf group, but not registered with a WMF account\n"

    for member in get_ldap_group_members('nda'):
        if member in users.keys():  # flagged via different account check
            if 'email' in users[member].keys():
                if users[member]['email'].endswith('wikimedia.org'):
                    log += member + " is in nda group, but registered with a WMF account\n"
    return log


# Make sure that all group members are defined in the YAML file
def validate_all_yaml_group_members_are_defined(known_users, yamldata):
    log = ""
    for group, groupdata in yamldata['groups'].items():
        if group == "absent" or group == "absent_ldap":
            continue
        for member in flatten(groupdata['members']):
            if member not in known_users:
                log += "Group " + group + " has a member not specified in the users section: "
                log += member + "\n"
    return log


# Make sure all members of a privileged LDAP group are defined in YAML
def validate_all_ldap_group_members_are_defined(known_users):
    log = ""
    for group in ['ops', 'wmf', 'nda']:
        ldap_members = get_ldap_group_members(group)

        for i in ldap_members:
            if i not in known_users:
                log += i + " present in privileged LDAP group (" + group + "),"
                log += "but not present in data.yaml\n"
    return log


# Warn if an account expires in 7 days or less
def print_pending_account_expirys(users):
    log = ""
    current_date = datetime.datetime.now().date()
    for i in users.keys():
        attrs = users[i]
        if 'expiry_date' in attrs.keys():
            expiry = datetime.datetime.strptime(str(attrs['expiry_date']), "%Y-%m-%d").date()
            delta = expiry - current_date
            if delta.days <= 7:
                log += "The NDA/MOU for " + i + " will lapse in " + str(delta.days) + " days.\n"
                log += "  Please get in touch with " + str(attrs['expiry_contact']) + "\n"
    return log


# Check that SSH keys in WMCS and production are distinct
# Also warn if a DSS key is found
def check_ssh_keys(yamldata):
    log = ""

    ldap_conn = ldap.initialize(LDAP_SERVER_URI)
    ldap_conn.protocol_version = ldap.VERSION3

    # These users use hardware-based key storage and are using the restricted bastion, whitelist
    whitelisted_users = ['bblack', 'tstarling']

    for username, userdata in yamldata['users'].items():
        ssh = userdata.get('ssh_keys', False)

        if ssh:
            wmcs_ssh_keys = set()
            prod_ssh_keys = set()
            ldapdata = ldap_conn.search_s(
                "ou=people,dc=wikimedia,dc=org",
                ldap.SCOPE_SUBTREE,
                "(&(objectclass=ldapPublicKey)(uid=" + username + "))",
                attrlist=['sshPublicKey'],
            )

            for i in ssh:
                key_type = i.split()[0]
                production_key = i.split()[1]

                if key_type == "ssh-dss":
                    log += username + " uses outdated DSA key for production access\n"
                prod_ssh_keys.add(production_key)

            if ldapdata:
                if ldapdata[0][1]:
                    for i in ldapdata[0][1]['sshPublicKey']:
                        wmcs_ssh_keys.add(i.split()[1])

            if wmcs_ssh_keys & prod_ssh_keys and username not in whitelisted_users:
                log += username + " uses the same SSH key(s) in WMCS and production:\n"
                log += "  " + str(wmcs_ssh_keys & prod_ssh_keys) + "\n"

    return log


# Check duplicated ops permissions
def validate_duplicated_ops_permissions(users):
    log = ""
    for i in users.keys():
        attrs = users[i]
        if 'ldap_only' in attrs.keys() and not attrs['ldap_only']:
            if "ops" in attrs['prod_groups']:
                ops_default_groups = set(['gitpuppet', 'ops'])
                groups = set(attrs['prod_groups'])
                if not ops_default_groups <= groups:
                    log += i + " doesn't have ops default groups\n"

                # ops and gitpuppet are default for all ops users
                # analytics-privatedata-users enables mysql access in addition to
                #    cluster-wide root permissions, so might be used in addition to ops privs
                # researchers enables mysql access in addition to cluster-wide root permissions,
                #    so might be used in addition to ops privs
                # ops-adm-group is auto-generated from the ops membership
                # statistics-privatedata-users enables mysql access as well
                # deploy-phabricator concerns handling of keyholder for deployment
                # analytics-search-users concerns user creation in HDFS
                # contint-docker is about being able to issue docker commands
                # builder-docker is about being able to issue docker commands
                # directly and execute scripts issuing docker commands
                groups.difference_update(['analytics-privatedata-users', 'gitpuppet', 'ops',
                                          'researchers', 'ops-adm-group',
                                          'statistics-privatedata-users',
                                          'contint-docker', 'builder-docker',
                                          'deploy-phabricator', 'analytics-search-users'])
                if len(set(groups)) > 0:
                    log += "Malformed membership for ops user " + i + ", has additional group(s): "
                    log += str(groups) + "\n"
    return log


def run_test(output):
    if output == "":
        return
    else:
        print output.rstrip('\n')


def main():

    yamldata = fetch_yaml_data()
    users = parse_users(yamldata)
    known_users = users.keys()

    run_test(validate_absented_users(yamldata))
    run_test(validate_email_addresses(users))
    run_test(validate_expiry_contacts(users))
    run_test(validate_mutually_exclusive_privileged_ldap_groups())
    run_test(validate_common_ops_group(yamldata))
    run_test(validate_all_yaml_group_members_are_defined(known_users, yamldata))
    run_test(validate_all_ldap_group_members_are_defined(known_users))
    run_test(validate_duplicated_ops_permissions(users))
    run_test(print_pending_account_expirys(users))
    run_test(validate_privileged_ldap_groups_memberships(users))
    run_test(check_ssh_keys(yamldata))


if __name__ == '__main__':
    main()
