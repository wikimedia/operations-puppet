#!/usr/bin/env python

# 2014 Chase Pettet
# beginnings of a linter for data.yaml

import sys
import yaml
import itertools
from collections import Counter
import collections


def flatten(lists):
    """flattens nested arrays"""
    return list(itertools.chain.from_iterable(lists))


def all_assigned_users(admins):
    """unique assigned users
    :param admins: hash from valid data.yaml
    :returns: list
    """
    nested_users_list = map(lambda u: u['members'], admins['groups'].values())
    return list(set(flatten(nested_users_list)))


def dict_sort(dictionary):
    # dumping ordered dict to yaml causes issues, return normal dict
    return dict(collections.OrderedDict(sorted(dictionary.items())))


def main():

    data = open('data.yaml', 'r')
    admins = yaml.safe_load(data)

    if 'sort' in sys.argv:
        print yaml.dump({'groups': dict_sort(admins['groups'])})
        print yaml.dump({'users': dict_sort(admins['users'])})

    if 'lint' in sys.argv:
        lint_error = False

        all_users = admins['users'].keys()
        grouped_users = all_assigned_users(admins)

        # ensure all assigned users exist
        non_existent_users = [u for u in grouped_users if u not in all_users]
        if non_existent_users:
            lint_error = True
            print "Users assigned that do not exist: %s" % (
                non_existent_users,)

        # ensure no two groups uses the same gid
        gids = filter(None, [
            v.get('gid', None) for k, v in admins['groups'].iteritems()])
        dupes = [k for k, v in Counter(gids).items() if v > 1]
        if dupes:
            lint_error = True
            print "Duplicate group GIDs: %s" % (dupes,)

        if lint_error:
            sys.exit(1)

if __name__ == '__main__':
    main()
