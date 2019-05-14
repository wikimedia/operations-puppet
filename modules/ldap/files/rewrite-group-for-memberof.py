#!/usr/bin/env python
# flake8: noqa
import ldap, argparse, sys, time
from ldap import modlist as modlist

group_container = "ou=groups,dc=wikimedia,dc=org"
binddn = "cn=admin,dc=wikimedia,dc=org"

p = argparse.ArgumentParser(usage="rewrite-group-for-memberof -g GROUPNAME")

p.add_argument("-g", "--group", action="store", type=str, dest="groupname", help="The group which should be rewritten for memberOf attributes (just the base group name, not the entire DN")

opt = p.parse_args()

if not opt.groupname:
    p.error("You need to provide the group name")

bindpw = raw_input("Enter password for " + binddn + ": ")

try:
    l = ldap.initialize('ldap://localhost:389')
    l.protocol_version = ldap.VERSION3
    l.simple_bind_s(binddn, bindpw)
except ldap.LDAPError, e:
    print e

ldapsearch = l.search_s(group_container, ldap.SCOPE_SUBTREE, "(&(objectclass=groupOfNames)(cn=" + opt.groupname + "))", attrlist=['member'],)

if not ldapsearch:
    print "Group not found, bailing out"
    sys.exit(1)

members = ldapsearch[0][1]
dn = ldapsearch[0][0]

print "Rewriting group", dn

empty_group= dict()
empty_group['member'] = ['']

try:
    empty_ldif = modlist.modifyModlist(members, empty_group)
    refill_ldif = modlist.modifyModlist(empty_group, members)
    l.modify_s(dn, empty_ldif)
    time.sleep(65)
    l.modify_s(dn, refill_ldif)
except ldap.LDAPError, e:
    print e

l.unbind_s()
