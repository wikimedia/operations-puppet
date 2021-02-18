#!/usr/bin/env python3
from argparse import (
    ArgumentParser,
    ArgumentDefaultsHelpFormatter,
    RawDescriptionHelpFormatter,
)
from pathlib import Path

import yaml

__doc__ = """
Given a list of users, generate a table of groups they belong to
Idea by Greg Grossmeier on T135187

Example:

  $ python3 matrix.py hashar thcipriani|column -t
  groups/user          hashar  thcipriani
  bastiononly          -       OK
  contint-admins       OK      OK
  contint-roots        OK      -
  deploy-phabricator   -       OK
  deploy-service       -       OK
  deployment           OK      OK
  gerrit-admin         OK      OK
  releasers-mediawiki  OK      -

Antoine Musso <hashar@free.fr> - 2016
Wikimedia Foundation Inc - 2016
"""


class MatrixArgumentFormatter(
    ArgumentDefaultsHelpFormatter, RawDescriptionHelpFormatter
):
    """Custom argument formatter"""


def flatten(memberlist, start=None):
    """
    Flatten a list recursively. Make sure to only flatten list elements, which
    is a problem with itertools.chain which also flattens strings. start defaults
    to None instead of the empty list to avoid issues with Copy by reference
    which is the default in python
    """

    if start is None:
        start = []

    for member in memberlist:
        if isinstance(member, list):
            flatten(member, start)
        else:
            start.append(member)
    return start


def get_args():
    """Get arguments."""
    parser = ArgumentParser(
        description=__doc__, formatter_class=MatrixArgumentFormatter
    )
    parser.add_argument(
        '--wikitext', help="Whether to output wikitext or not.", action="store_true"
    )
    parser.add_argument(
        '--admin-file',
        help="path to admin module data.yaml file",
        type=Path,
        default=Path(__file__).parents[0] / 'data.yaml',
    )
    parser.add_argument('user', help="User to display.", nargs='+')

    return parser.parse_args()


def main():
    """Main function."""
    args = get_args()
    users = args.user

    top_left = 'groups/users'
    if args.wikitext:
        header_separator = '\n! '
        top_left = '! ' + top_left
        row_separator = '\n|'
        group_begin = '|-\n|'
        positive = 'style="background-color:lightgreen" |OK'
    else:
        header_separator = '\t'
        row_separator = '\t'
        group_begin = ''
        positive = 'OK'

    admins = yaml.safe_load(args.admin_file.read_text())

    all_users = list(admins.get('users'))
    unknown = set(users) - set(all_users)
    if unknown:
        print('Unknown user(s):', ', '.join(unknown))
        return 1

    if args.wikitext:
        print('\n{| class="wikitable"')
    print(header_separator.join([top_left] + users))

    groups = admins.get('groups', {})
    for group_name in sorted(groups.keys()):
        group = groups[group_name]

        group_members = set(flatten(group['members']))
        if set(users).isdisjoint(group_members):
            continue

        members = set(users) & set(group_members)
        print(
            group_begin
            + row_separator.join(
                [group_name] + [positive if u in members else ' ' for u in users]
            )
        )

    if args.wikitext:
        print('|}')
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
