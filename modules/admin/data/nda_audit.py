#!/usr/bin/env python
#
# Copyright (c) 2016 Wikimedia Foundation, Inc.
#
# This script parses our data.yaml file for all users and enriches the
# information using information gathered from the production/Labs LDAP tree. It
# finally outputs the information with non-technical labels into a CSV.
#
# It's currently being used to perform user access and NDA audits with the
# WMF's Legal department.

import sys
import yaml
import ldap
import csv


def extract_from_yaml():
    data = open('data.yaml', 'r')
    admins = yaml.safe_load(data)

    users = {}

    for username, userdata in admins['users'].items():
        if userdata['ensure'] == 'absent':
            continue

        groups = []
        for group, groupdata in admins['groups'].items():
            if username in groupdata['members']:
                groups.append(group)

        users[username] = {
            'realname': userdata['realname'],
            'uid': userdata['uid'],
            'prod_groups': groups,
            'has_server_access': (len(userdata['ssh_keys']) > 0),
        }

    return users


def enrich_from_ldap(users):
    # needs some configuration
    ldap_conn = ldap.initialize('ldap://%s:389' % 'localhost')
    ldap_conn.protocol_version = ldap.VERSION3

    base_dn = "dc=wikimedia,dc=org"
    people_dn = "ou=people," + base_dn
    groups_dn = "ou=groups," + base_dn

    for username in users.keys():
        ldapdata = ldap_conn.search_s(
                people_dn,
                ldap.SCOPE_SUBTREE,
                "(&(objectclass=inetOrgPerson)(uid=" + username + "))",
                attrlist=['*', '+']
            )
        attrs = ldapdata[0][1]
        user_dn = ldapdata[0][0]

        ldapdata = ldap_conn.search_s(
                groups_dn,
                ldap.SCOPE_SUBTREE,
                "(&(objectclass=groupOfNames)(member=" + user_dn + "))",
                attrlist=['cn'],
            )
        groups = [l[1]['cn'][0] for l in ldapdata]

        users[username]['email'] = ','.join(attrs['mail'])
        users[username]['has_nda_group'] = ('nda' in groups)
        users[username]['has_wmf_group'] = ('wmf' in groups)
        users[username]['ldap_groups'] = groups

    return users


def main():
    users = extract_from_yaml()
    users = enrich_from_ldap(users)

    userwriter = csv.writer(sys.stdout, delimiter=';')
    userwriter.writerow([
        'Username',
        'Full name',
        'email',
        'Has server access',
        'Has LDAP NDA access',
        'Has LDAP Staff access',
    ])

    for username in sorted(users.keys()):
        userdata = users[username]
        userwriter.writerow([
            username,
            userdata['realname'],
            userdata['email'],
            ('yes' if userdata['has_server_access'] else 'no'),
            ('yes' if userdata['has_nda_group'] else 'no'),
            ('yes' if userdata['has_wmf_group'] else 'no'),
        ])


if __name__ == '__main__':
    main()
