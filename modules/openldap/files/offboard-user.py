#!/usr/bin/env python
#
# Copyright (c) 2017 Wikimedia Foundation, Inc.

# This script offboards a user from LDAP. In the default case a user can
# retain standard Nova group memberships and only loses access to
# privileged groups. If the user signs a volunteer NDA, access to privileged
# groups is retained as well (but the user switched from the "wmf" to the "nda"
# group. For exceptional cases (e.g. in case of suspicious activity), there's
# also the possibility to remove a user from all groups
# Initially only an LDIF is written, but not automatically modified in LDAP

import sys
from optparse import OptionParser

try:
    import ldap
except ImportError:
    print "Unable to import Python LDAP"
    sys.exit(1)


def main():

    ldif = ""

    parser = OptionParser()
    parser.set_usage("offboard-user [--drop-all] [--list-only] [--turn-volunteer] [<username>")
    parser.add_option("--drop-all", action="store_true", dest="remove_all_groups", default=False,
                      help="""By default unprivileged group group memberships are retained.
                      If this option is set, then all group memberships are removed""")
    parser.add_option("--list-only", action="store_true", dest="dry_run", default=False,
                      help="Only list group memberships, don't do anything")
    parser.add_option("--turn-volunteer", action="store_true", dest="turn_volunteer", default=False,
                      help="If a former WMF staff member wishes to resume under a volunteer NDA")

    (options, args) = parser.parse_args()

    if len(args) < 1 or len(args) > 1:
        parser.error("You need to specify a username to offboard")

    ldap_conn = ldap.initialize('ldaps://ldap-labs.eqiad.wikimedia.org:636')
    ldap_conn.protocol_version = ldap.VERSION3

    base_dn = "dc=wikimedia,dc=org"
    projects_dn = "ou=projects," + base_dn
    groups_dn = "ou=groups," + base_dn
    servicegroups_dn = "ou=servicegroups," + base_dn

    ADD_GROUP = """dn: {group_name}
changetype: modify
add: member
member: {user_dn}
-
"""
    REMOVE_GROUP = """dn: {group_name}
changetype: modify
delete: member
member: {user_dn}
-
"""

    # TODO: add more groups after validating priv. status
    privileged_groups = ['cn=nda,ou=groups,dc=wikimedia,dc=org',
                         'cn=wmf,ou=groups,dc=wikimedia,dc=org',
                         'cn=ops,ou=groups,dc=wikimedia,dc=org',
                         'cn=librenms-readers,ou=groups,dc=wikimedia,dc=org',
                         'cn=grafana-admin,ou=groups,dc=wikimedia,dc=org',
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
    member_set = set(memberships)
    priv_set = set(privileged_groups)

    if len(memberships) == 0:
        print "Is not member of any LDAP group"
    else:
        print "Is member of the following unprivileged LDAP groups:"
        for group in memberships:
            if group not in priv_set:
                if options.remove_all_groups:
                    ldif += REMOVE_GROUP.format(group_name=group, user_dn=user_dn)
                    print " ", group, "(removing)"
                else:
                    print " ", group, "(can be retained)"

    if len(project_admins) == 0:
        print "Is not a project admin in Nova"
    else:
        print "Is project admin of the following projects:"
        for group in project_admins:
            if options.remove_all_groups:
                ldif += REMOVE_GROUP.format(group_name=group, user_dn=user_dn)
                print " ", group, "(removing)"
            else:
                print " ", group, "(can be retained)"

    if len(member_set & priv_set) > 0:
        print "Privileged groups:"
        for priv_group in set(member_set & priv_set):
            if not options.remove_all_groups:  # Skip if we're pruning all groups anyway
                if options.turn_volunteer:
                    if priv_group == 'cn=wmf,ou=groups,dc=wikimedia,dc=org':
                        ldif += REMOVE_GROUP.format(group_name=priv_group, user_dn=user_dn)
                        ldif += ADD_GROUP.format(group_name=priv_group, user_dn=user_dn)
                        print "  ", priv_group, "(converted to nda group)"
                    else:
                        print "  ", priv_group, "(can be retained)"
                else:
                    ldif += REMOVE_GROUP.format(group_name=priv_group, user_dn=user_dn)
                    print "  ", priv_group, "(removing)"
    else:
        print "Is not a member in any privileged group"

    if not options.dry_run:
        try:
            with open(uid + ".ldif", "w") as ldif_file:
                ldif_file.write(ldif)
            print "LDIF file written to ", uid + ".ldif"
        except IOError, e:
            print "Error:", e
            sys.exit(1)


if __name__ == '__main__':
    main()
