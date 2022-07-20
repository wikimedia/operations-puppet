#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
from collections import OrderedDict
import sys
import toml


def item_or_none(alist, i):
    try:
        return alist[i]
    except IndexError:
        return None


def merge(a, b, field=None):
    if b is None:
        return a
    elif isinstance(a, list) and isinstance(b, list):
        if field == 'runners':
            # Merge list of runners according to index
            return [
                merge(item_or_none(a, i), item_or_none(b, i))
                for i in range(0, max(len(a), len(b)))
            ]
        else:
            # Concatenate all other lists
            return a + b
    elif isinstance(a, OrderedDict) and isinstance(b, OrderedDict):
        return OrderedDict([
            (k, merge(a.get(k), b.get(k), field=k))
            for k in set(b.keys()) | set(a.keys())
        ])
    return b


def load_config(path):
    with open(path) as f:
        return toml.loads(f.read(), OrderedDict)


parser = argparse.ArgumentParser(
    description='Deeply merge two or more GitLab runner config files',
)

parser.add_argument('config_paths', metavar='FILE', type=str, nargs='+')
args = parser.parse_args()

config = load_config(args.config_paths[0])

for path in args.config_paths[1:]:
    config = merge(config, load_config(path))

toml.dump(config, sys.stdout)
