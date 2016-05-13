#!/usr/bin/env python2
#
# Given a list of users, generate a table of groups they belong to
# Idea by Greg Grossmeier on T135187
#
# Example:
# 
#   $ python matrix.py hashar thcipriani|column -t
#   grp/user             hashar  thcipriani
#   bastiononly          -       OK
#   contint-admins       OK      OK
#   contint-roots        OK      -
#   deploy-phabricator   -       OK
#   deploy-service       -       OK
#   deployment           OK      OK
#   gerrit-admin         OK      OK
#   releasers-mediawiki  OK      -
#   $
#
# Antoine Musso <hashar@free.fr> - 2016
# Wikimedia Foundation Inc - 2016

import sys

import yaml

if len(sys.argv) <= 1:
    print 'usage: matrix.py user1 [user2 ..]'
    sys.exit(1)

users = sys.argv[1:]

with open('data.yaml', 'r') as f:
    admins = yaml.safe_load(f)

all_users = admins.get('users').keys()
unknown = set(users) - set(all_users)
if unknown:
    print 'Unknown user(s):', ', '.join(unknown)
    sys.exit(1)

print '\t'.join(['grp/users'] + users)

groups = admins.get('groups', {})
for group_name in sorted(groups.keys()):
    group = groups[group_name]

    group_members = set(group['members'])
    if set(users).isdisjoint(group_members):
        continue

    members = set(users) & set(group_members)
    print '\t'.join(
        [group_name] +
        ['OK' if u in members else '-'
            for u in users])
