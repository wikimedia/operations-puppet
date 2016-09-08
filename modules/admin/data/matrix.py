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
    print 'usage: matrix.py [--wikitext] user1 [user2 ..]'
    sys.exit(1)

users = sys.argv[1:]

TOP_LEFT = 'grp/users'
HEADER_SEPARATOR = '\t'
HEADER_END = ''
ROW_SEPARATOR = '\t'
GROUP_BEGIN = ''
mode = 'plain'
if len(users) and users[0] == '--wikitext':
    users = users[1:]
    HEADER_SEPARATOR = '\n! '
    TOP_LEFT = '! ' + TOP_LEFT
    HEADER_END = '\n'
    ROW_SEPARATOR = '\n|'
    GROUP_BEGIN = '|-\n|'
    mode = 'wikitext'

with open('data.yaml', 'r') as f:
    admins = yaml.safe_load(f)

all_users = admins.get('users').keys()
unknown = set(users) - set(all_users)
if unknown:
    print 'Unknown user(s):', ', '.join(unknown)
    sys.exit(1)

if mode == 'wikitext':
    print '\n{| class="wikitable"'
print HEADER_SEPARATOR.join([TOP_LEFT] + users) + HEADER_END

groups = admins.get('groups', {})
for group_name in sorted(groups.keys()):
    group = groups[group_name]

    group_members = set(group['members'])
    if set(users).isdisjoint(group_members):
        continue

    members = set(users) & set(group_members)
    print GROUP_BEGIN + ROW_SEPARATOR.join(
        [group_name] +
        ['OK' if u in members else ' '
            for u in users])

if mode == 'wikitext':
    print '|}'