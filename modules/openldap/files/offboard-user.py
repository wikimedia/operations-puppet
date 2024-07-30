#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2017-2019 Wikimedia Foundation, Inc.

# This script offboards a user from LDAP. In the default case a user can
# retain standard Nova group memberships and only loses access to
# privileged groups. If the user signs a volunteer NDA, access to privileged
# groups is retained as well (but the user switched from the "wmf" to the "nda"
# group. For exceptional cases (e.g. in case of suspicious activity), there's
# also the possibility to remove a user from all groups
# Initially only an LDIF is written, but not automatically modified in LDAP

import configparser
import os
import shutil
import subprocess
import sys
import tempfile

from optparse import OptionParser

import yaml

try:
    from phabricator import Phabricator
except ImportError:
    print("Unable to import Python Phabricator module")
    sys.exit(1)

try:
    import ldap
except ImportError:
    print("Unable to import Python LDAP")
    sys.exit(1)

base_dn = "dc=wikimedia,dc=org"
groups_dn = "ou=groups," + base_dn
servicegroups_dn = "ou=servicegroups," + base_dn


def flatten(inlist, flattened=None):
    '''
    Flatten a list recursively. Make sure to only flatten list elements, which
    is a problem with itertools.chain which also flattens strings. a defaults
    to None instead of the empty list to avoid issues with Copy by reference
    which is the default in python
    '''

    if flattened is None:
        flattened = []

    for i in inlist:
        if isinstance(i, list):
            flatten(i, flattened)
        else:
            flattened.append(i)
    return flattened


def fetch_yaml_data():
    tmp_dir = tempfile.mkdtemp()
    try:
        subprocess.check_output(["git", "clone",
                                 "https://gerrit.wikimedia.org/r/operations/puppet.git",
                                 tmp_dir], stderr=subprocess.STDOUT, shell=False)
    except subprocess.CalledProcessError as e:
        print("git checkout failed", e.returncode)
        shutil.rmtree(tmp_dir)
        sys.exit(1)

    with open(os.path.join(tmp_dir, 'modules/admin/data/data.yaml'), 'r') as data:
        try:
            yamldata = yaml.safe_load(data)
        except yaml.YAMLError:
            print('Failed to parse data.yaml')
            shutil.rmtree(tmp_dir)
            sys.exit(1)

    shutil.rmtree(tmp_dir)
    return yamldata


def parse_users(yamldata):
    users = {}

    for table in ['users']:
        for username, userdata in yamldata[table].items():
            groups = []
            for group, groupdata in list(yamldata['groups'].items()):
                if username in flatten(groupdata['members']):
                    groups.append(group)

            if table == 'users':
                if 'krb' in userdata:
                    krb_state = userdata['krb']
                else:
                    krb_state = 'absent'

                users[username] = {
                    'ensure': userdata['ensure'],
                    'ldap_only': False,
                    'krb': krb_state,
                    'uid': userdata['uid'],
                    'prod_groups': groups,
                }

    return users


def set_cookie(lc_object, pctrls, pagesize):
    cookie = pctrls[0].cookie
    lc_object.cookie = cookie
    return cookie


def does_user_attr_exist(uid, attribute):
    ldap_conn = ldap.initialize('ldaps://ldap-rw.eqiad.wikimedia.org:636')
    ldap_conn.protocol_version = ldap.VERSION3
    ldapdata = ldap_conn.search_s(
        base_dn,
        ldap.SCOPE_SUBTREE,
        "(&(objectclass=posixAccount)(uid=" + uid + "))",
        attrlist=[attribute],
    )

    if not ldapdata[0][1]:
        return False

    return True


def offboard_ldap(uid, remove_all_groups, turn_volunteer, dry_run, disable_user):
    ldap_conn = ldap.initialize('ldaps://ldap-rw.eqiad.wikimedia.org:636')
    ldap_conn.protocol_version = ldap.VERSION3
    ldif = ""

    ADD_GROUP = """dn: {group_name}
changetype: modify
add: member
member: {user_dn}

"""
    REMOVE_GROUP = """dn: {group_name}
changetype: modify
delete: member
member: {user_dn}

"""

    REMOVE_PASSWORD = """dn: {user_dn}
changetype: modify
delete: userPassword
"""

    lc = ldap.controls.SimplePagedResultsControl(criticality=False, size=1024, cookie='')

    privileged_groups = ['cn=nda,ou=groups,dc=wikimedia,dc=org',
                         'cn=wmf,ou=groups,dc=wikimedia,dc=org',
                         'cn=ops,ou=groups,dc=wikimedia,dc=org',
                         'cn=ldap_ops,ou=groups,dc=wikimedia,dc=org',
                         'cn=wmde,ou=groups,dc=wikimedia,dc=org',
                         'cn=grafana-admin,ou=groups,dc=wikimedia,dc=org',
                         'cn=ciadmin,ou=groups,dc=wikimedia,dc=org',
                         'cn=releng,ou=groups,dc=wikimedia,dc=org',
                         'cn=archiva-deployers,ou=groups,dc=wikimedia,dc=org',
                         'cn=gerritadmin,ou=groups,dc=wikimedia,dc=org',
                         'cn=idptest-users,ou=groups,dc=wikimedia,dc=org',
                         'cn=sre-admins,ou=groups,dc=wikimedia,dc=org',
                         'cn=ops-limited,ou=groups,dc=wikimedia,dc=org',
                         'cn=dns-admins,ou=groups,dc=wikimedia,dc=org',
                         'cn=superset-admins,ou=groups,dc=wikimedia,dc=org',
                         'cn=project-cloudinfra,ou=groups,dc=wikimedia,dc=org',
                         'cn=tools.admin,ou=servicegroups,dc=wikimedia,dc=org']
    ldapdata = ldap_conn.search_s(
        base_dn,
        ldap.SCOPE_SUBTREE,
        "(&(objectclass=posixAccount)(uid=" + uid + "))",
        attrlist=['uid'],
    )

    if len(ldapdata) == 0:
        print("LDAP user", uid, "not found")
        return

    user_dn = ldapdata[0][0]

    group_ous = [groups_dn, servicegroups_dn]

    memberships = []

    for ou in group_ous:
        while True:
            ldapdata = ldap_conn.search_ext(
                ou,
                ldap.SCOPE_SUBTREE,
                "(objectclass=groupOfNames)",
                attrlist=['member'],
                serverctrls=[lc]
            )

            rtype, rdata, rmsgid, serverctrls = ldap_conn.result3(ldapdata)
            for dn, attrs in rdata:
                if user_dn.encode() in attrs['member']:
                    memberships.append(dn)

            page_control = [c for c in serverctrls
                            if c.controlType == ldap.controls.SimplePagedResultsControl.controlType]

            cookie = set_cookie(lc, page_control, 1024)
            if not cookie:
                break

    print("User DN:", user_dn)
    member_set = set(memberships)
    priv_set = set(privileged_groups)

    has_openstack_projects = False

    if len(memberships) == 0:
        print("Is not member of any LDAP group")
    else:
        print("Is member of the following unprivileged LDAP groups:")
        for group in memberships:
            if group not in priv_set:
                if remove_all_groups:
                    if group.startswith("cn=project-"):
                        print(" ", group, "(Cloud VPS project, must be removed manually)")
                        has_openstack_projects = True
                    else:
                        ldif += REMOVE_GROUP.format(group_name=group, user_dn=user_dn)
                        print(" ", group, "(removing)")
                else:
                    print(" ", group, "(can be retained)")

    if len(member_set & priv_set) > 0:
        print("Privileged groups:")
        for priv_group in set(member_set & priv_set):
            if not remove_all_groups:  # Skip if we're pruning all groups anyway
                if turn_volunteer:
                    if priv_group == 'cn=wmf,ou=groups,dc=wikimedia,dc=org':
                        ldif += REMOVE_GROUP.format(group_name=priv_group, user_dn=user_dn)
                        ldif += ADD_GROUP.format(group_name='cn=nda,ou=groups,dc=wikimedia,dc=org',
                                                 user_dn=user_dn)
                        print("  ", priv_group, "(converted to nda group)")
                    else:
                        print("  ", priv_group, "(can be retained)")
                else:
                    if priv_group.startswith("cn=project-"):
                        print(" ", priv_group, "(Cloud VPS project, must be removed manually)")
                        has_openstack_projects = True
                    else:
                        ldif += REMOVE_GROUP.format(group_name=priv_group, user_dn=user_dn)
                        print("  ", priv_group, "(removing)")
    else:
        print("Is not a member in any privileged group")

    if has_openstack_projects:
        print("To remove membership in Cloud VPS projects mentioned above, please see:")
        print(
            "  https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/"
            "Admin/Projects_lifecycle#Manage_project_access"
        )

    attrs_to_remove = ['mail', 'sshPublicKey']
    if disable_user:
        ldif += REMOVE_PASSWORD.format(user_dn=user_dn)
        removed_attrs = 0
        for attr in attrs_to_remove:
            if does_user_attr_exist(uid, attr):
                ldif += "-\n"
                ldif += "delete: " + attr + "\n"
                removed_attrs += 1
        if removed_attrs:
            ldif += "-\n"

        print("  Removing user attributes")

    if not dry_run and ldif:
        try:
            with open(uid + ".ldif", "w") as ldif_file:
                ldif_file.write(ldif)
            print("LDIF file written to ", uid + ".ldif")
            print("Please review and if all is well, you can effect the change running")
            cmd = ""
            if disable_user:
                cmd += 'ldapsearch -x -D "cn=scriptuser,ou=profile,dc=wikimedia,dc=org" -W uid='
                cmd += uid + ' > disable-' + uid + '.pre.ldif\n'
            cmd += 'ldapmodify -H "ldap://ldap-rw.eqiad.wikimedia.org:389/" -x'
            cmd += ' -D "cn=scriptuser,ou=profile,dc=wikimedia,dc=org" -W -f ' + uid + ".ldif\n"
            if disable_user:
                cmd += 'ldapsearch -x -D "cn=scriptuser,ou=profile,dc=wikimedia,dc=org" -W uid='
                cmd += uid + ' > disable-' + uid + '.post.ldif\n'
            cmd += 'To obtain the password run\n'
            cmd += 'sudo cat /etc/ldapvi.conf'
            print(cmd)
        except IOError as e:
            print("Error:", e)
            sys.exit(1)


def get_phabricator_client():
    """Return a Phabricator client instance"""

    phab_bot_conf = '/etc/phabricator_offboarding.conf'
    parser = configparser.ConfigParser()
    parser.read(phab_bot_conf)

    try:
        client = Phabricator(
            username=parser.get('phabricator_bot', 'username'),
            token=parser.get('phabricator_bot', 'token'),
            host=parser.get('phabricator_bot', 'host'))
    except configparser.NoSectionError:
        print("Failed to open config file for Phabricator bot user:", phab_bot_conf)
        sys.exit(1)

    return client


def get_phabricator_subproject(phab_client, group_name):
    """return all the subprojects names for a project"""
    phid = None
    project = phab_client.project.query(names=[group_name])
    if not project['data']:
        print("unable to find project: " + group_name)
        sys.exit(1)

    for _phid, data in project['data'].items():
        if data['name'] == group_name:
            phid = _phid
            break
    else:
        # we shouldn't ever reach here
        print("Failed to retrieve phid for: " + group_name)
        sys.exit(1)

    subprojects = phab_client.project.search(constraints={'parents': [phid]})
    if not subprojects.get('data'):
        print("unable to find any subprojects for: " + group_name)
        sys.exit(1)
    return {subproject['fields']['name'] for subproject in subprojects['data']}


def offboard_analytics(username):
    pii_sensitive_groups = ['analytics-privatedata-users', 'analytics-search-users',
                            'analytics-product-users', 'analytics-admins',
                            'analytics-wmde-users', 'ops']

    yamldata = fetch_yaml_data()
    users = parse_users(yamldata)
    if username not in users:
        print(username, 'does not exist in modules/admin/data/data.yaml')
        return
    elif users[username]['ensure'] == 'absent':
        print(username, 'has already been offboarded in  modules/admin/data/data.yaml')
        print('Hadoop/Hive PII check cannot be performed.')
        print('please check a previous revision where `{} ensure: present`'.format(username))
    shell_groups = users[username]['prod_groups']

    for group in shell_groups:
        if group in pii_sensitive_groups:
            print(group, "grants access to Hadoop/Hive, check PII leftovers and Hue account.")
    print()


def offboard_kerberos(username):

    yamldata = fetch_yaml_data()
    users = parse_users(yamldata)

    if username not in users:
        return
    elif users[username]['krb'] == 'present':
        print(username, 'has a Kerberos user principal, make sure to remove it')


def remove_user_from_project(user_phid, project_phid, phab_client):
    t = {}
    t['type'] = 'members.remove'
    t['value'] = [user_phid]

    phab_client.project.edit(transactions=[t], objectIdentifier=project_phid)


def confirm_removal(group):
    choice = ""
    while choice not in ["y", "n"]:
        choice = input("Remove group " + group + "? ").strip().lower()
    return choice == "y"


def offboard_phabricator(username, remove_all_groups, dry_run, turn_volunteer):
    phab_client = get_phabricator_client()

    group_memberships = []

    # TODO: add more groups after validating priv. status
    privileged_parent_projects = set(['acl*security'])
    privileged_projects = set(['WMF-NDA', 'Security', 'acl*sre-team', 'acl*WMF-FR',
                               'acl*communityliaison_policy_admins', 'acl*procurement-review',
                               'acl*annual_report_policy_admins', 'acl*security_team',
                               'acl*research_collaborations_policy_admins', 'WMF-SIEM',
                               'acl*support_and_safety_policy_admins'])

    user_query = phab_client.user.query(usernames=[username])
    if not user_query:
        print("Phabricator user", username, "not found")
        sys.exit(1)
    else:
        phid_user = user_query[0]['phid']

    for project in privileged_parent_projects:
        privileged_projects.update(get_phabricator_subproject(phab_client, project))

    project_query = phab_client.project.query(members=[phid_user])
    if not project_query.get('data'):
        print("Not present in any project, nothing to be done")
        return
    else:
        groups = project_query['data'].keys()
        for membership in groups:
            group_memberships.append(
                (project_query['data'][membership]['name'],
                 project_query['data'][membership]['phid']))

    if dry_run:
        print("Phabricator user", username, "is present in the following groups:")
        for i in group_memberships:
            if dry_run:
                print(i[0])
    else:
        for i in group_memberships:
            if remove_all_groups:
                if confirm_removal(i[0]):
                    remove_user_from_project(phid_user, i[1], phab_client)
            else:
                if i[0] in privileged_projects:
                    if turn_volunteer:
                        print(i[0], "is an privileged group, but can be retained")
                    else:
                        if confirm_removal(i[0]):
                            remove_user_from_project(phid_user, i[1], phab_client)
                else:
                    print(i[0], "is an unprivileged group, can be retained")


def main():

    parser = OptionParser()
    parser.set_usage("""offboard-user [--drop-all] [--list-only] [--skip-analytics]
                     [--disable-user] [--turn-volunteer] [ -p  | -l ]""")
    parser.add_option("--drop-all", action="store_true", dest="remove_all_groups", default=False,
                      help="""By default unprivileged group group memberships are retained.
                      If this option is set, then all group memberships are removed""")
    parser.add_option("--list-only", action="store_true", dest="dry_run", default=False,
                      help="Only list group memberships, don't do anything")
    parser.add_option("--skip-analytics", action="store_true", dest="skip_analytics",
                      help="When offboarding an LDAP user, skip the check for analytics groups")
    parser.add_option("--turn-volunteer", action="store_true", dest="turn_volunteer", default=False,
                      help="If a former WMF staff member wishes to resume under a volunteer NDA")
    parser.add_option("--disable-user", action="store_true", dest="disableuser",
                      help="If this option is enabled, the user password and mail are removed")

    parser.add_option("--ldap-user", "-l", action="store", dest="ldap_username", default=False,
                      help="User name in LDAP/wikitech of the user to be removed")
    parser.add_option("--phab-user", "-p", action="store", dest="phab_username", default=False,
                      help="User name in Phabricator of the user to be removed")

    (options, args) = parser.parse_args()

    if not options.ldap_username and not options.phab_username:
        parser.error("You need to specify a username in LDAP (-l) and/or Phabricator (-p)")

    if options.ldap_username:
        offboard_ldap(options.ldap_username, options.remove_all_groups,
                      options.turn_volunteer, options.dry_run, options.disableuser)

        offboard_kerberos(options.ldap_username)

        if not options.skip_analytics:
            offboard_analytics(options.ldap_username)

    else:
        print("Skipping LDAP offboarding, use -l USERNAME to run it at a later point")

    if options.phab_username:
        offboard_phabricator(options.phab_username, options.remove_all_groups, options.dry_run,
                             options.turn_volunteer)
    else:
        print("Skipping Phabricator offboarding, use -p USERNAME to run it at later point")


if __name__ == '__main__':
    main()
