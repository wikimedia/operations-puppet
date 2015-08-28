#!/usr/bin/env python

# 2014 Chase Pettet
# Reads data.yaml and sorts it

import sys
import yaml
import collections


def dict_sort(dictionary):
    # dumping ordered dict to yaml causes issues, return normal dict
    return dict(collections.OrderedDict(sorted(dictionary.items())))


def flatten_members(members):
    res = []
    for m in members:
        if isinstance(m, (list, tuple)):
            res.extend(flatten_members(m))
        else:
            res.append(m)
    # Make them uniq
    return list(collections.OrderedDict.fromkeys(res))


def main():

    data = open('data.yaml', 'r')
    admins = yaml.safe_load(data)

    for group in admins['groups'].itervalues():
        group['members'] = flatten_members(group['members'])

    if 'sort' in sys.argv:
        print yaml.dump({'groups': dict_sort(admins['groups'])})
        print yaml.dump({'users': dict_sort(admins['users'])})

if __name__ == '__main__':
    main()
