#!/usr/bin/env python
#
# Copyright (c) 2017 Wikimedia Foundation, Inc.

import sys
import ldap
from optparse import OptionParser

try:
    import ldap
except ImportError:
    print "Unable to import Python LDAP"
    sys.exit(1)


def remove_group(group_name, user_dn):
    change_ldif = ""
    change_ldif += "dn: " + group_name + "\n"
    change_ldif += "changetype: modify\n"
    change_ldif += "delete: member\n"
    change_ldif += "member: " + user_dn + "\n"
    change_ldif += "-"
    return change_ldif


def main():

    ldif = ""

    parser = OptionParser()
    parser.set_usage("offboard-user [--complete] [<username>")
    parser.add_option("--complete", action="store_true", dest="remove_all_groups", default=False,
                      help="""By default unprivilegeg group group memberships are retained.
                      If this option is set, then all group memberships are removed""")
    parser.add_option("--dry-run", action="store_true", dest="dry_run", default=False,
                      help="Only list group memberships, don't do anything")

    (options, args) = parser.parse_args()

    if len(args) < 1 or len(args) > 1:
        parser.error("You need to specific a username to offboard")

    ldap_conn = ldap.initialize('ldaps://ldap-labs.eqiad.wikimedia.org:636')
    ldap_conn.protocol_version = ldap.VERSION3

    base_dn = "dc=wikimedia,dc=org"
    people_dn = "ou=people," + base_dn
    projects_dn = "ou=projects," + base_dn
    groups_dn = "ou=groups," + base_dn
    servicegroups_dn = "ou=servicegroups," + base_dn

    # TODO: add more groups after validating
    privileged_groups = ['cn=nda,ou=groups,dc=wikimedia,dc=org',
                         'cn=wmf,ou=groups,dc=wikimedia,dc=org',
                         'cn=ops,ou=groups,dc=wikimedia,dc=org',
                         'cn=tools.admin,ou=servicegroups,dc=wikimedia,dc=org']
    uid = args[0]
    ldapdata = ldap_conn.search_s(
        base_dn,
        ldap.SCOPE_SUBTREE,
        "(&(objectclass=posixAccount)(uid=" + uid + "))",
        attrlist=['uid'],
    )

    user_dn = ldapdata[0][0]

    group_ous = [projects_dn, groups_dn, servicegroups_dn]

    memberships = []
    project_admins = []

    for ou in group_ous:
        ldapdata = ldap_conn.search_s(
            ou,
            ldap.SCOPE_SUBTREE,
            "(objectclass=groupOfNames)",
            attrlist=['member'],
        )

        for i in ldapdata:
            if user_dn in i[1]['member']:
                memberships.append(i[0])

    ldapdata = ldap_conn.search_s(
        projects_dn,
        ldap.SCOPE_SUBTREE,
        "(&(objectclass=organizationalrole)(cn=projectadmin))",
        attrlist=['roleOccupant'],
    )

    for i in ldapdata:
        if 'roleOccupant' in i[1].keys():
            if user_dn in i[1]['roleOccupant']:
                project_admins.append(i[0])

    print "User DN:", user_dn

    if len(memberships) == 0:
        print "Is not member of any LDAP groups"
    else:
        print "Is member of the following LDAP groups:"
        for group in memberships:
            print " ", group
            if options.remove_all_groups:
                ldif += remove_group(group, user_dn)

    if len(project_admins) == 0:
        print "Is not a project admin in Nova"
    else:
        print "Is project admin of the following projects:"
        for group in project_admins:
            print " ", group
            if options.remove_all_groups:
                ldif += remove_group(group, user_dn)

    member_set = set(memberships)
    priv_set = set(privileged_groups)
    if len(member_set & priv_set) > 0:
        print "Privileged groups:"
        for priv_group in set(member_set & priv_set):
            print "  ", priv_group
            if not options.remove_all_groups:  # Skip if we're pruning all groups anyway
                ldif += remove_group(priv_group, user_dn)
    else:
        print "Is not a member in any privileged group"

    if not options.dry_run:
        print ldif


if __name__ == '__main__':
    main()
