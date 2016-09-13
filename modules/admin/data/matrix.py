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

import argparse
import sys

import yaml

parser = argparse.ArgumentParser(
    description="Utility to generate a matrix of production users and their groups",
)
parser.add_argument('--wikitext',
                    help="Whether to output wikitext or not.",
                    action="store_true")
parser.add_argument('user',
                    help="User to display.",
                    nargs='+')

args = parser.parse_args()
users = args.user

TOP_LEFT = 'grp/users'
if args.wikitext:
    HEADER_SEPARATOR = '\n! '
    TOP_LEFT = '! ' + TOP_LEFT
    ROW_SEPARATOR = '\n|'
    GROUP_BEGIN = '|-\n|'
else:
    HEADER_SEPARATOR = '\t'
    ROW_SEPARATOR = '\t'
    GROUP_BEGIN = ''

with open('data.yaml', 'r') as f:
    admins = yaml.safe_load(f)

all_users = admins.get('users').keys()
unknown = set(users) - set(all_users)
if unknown:
    print 'Unknown user(s):', ', '.join(unknown)
    sys.exit(1)

if args.wikitext:
    print '\n{| class="wikitable"'
print HEADER_SEPARATOR.join([TOP_LEFT] + users)

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

if args.wikitext:
    print '|}'
