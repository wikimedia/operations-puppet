#!/usr/bin/env python

# 2014 Chase Pettet
# Tests to perform basic validation on data.yaml

from collections import Counter
import itertools
import os
import unittest
import yaml


class DataTest(unittest.TestCase):
    def flatten(self, lists):
        """flattens nested arrays"""
        return list(itertools.chain.from_iterable(lists))

    def all_assigned_users(self, admins):
        """unique assigned users
        :param admins: hash from valid data.yaml
        :returns: list
        """
        nested_users_list = map(
            lambda u: u['members'], admins['groups'].values()
        )
        return list(set(self.flatten(nested_users_list)))

    def testDataDotYaml(self):

        with open(os.path.join(os.path.dirname(__file__), 'data.yaml')) as f:
            admins = yaml.safe_load(f)

        all_users = list(admins['users'])
        grouped_users = self.all_assigned_users(admins)

        # ensure all assigned users exist
        non_existent_users = [u for u in grouped_users if u not in all_users]
        self.assertEqual(
            [],
            non_existent_users,
            'Users assigned that do not exist: %r' % non_existent_users
        )

        # ensure no two groups uses the same gid
        gids = filter(None, [
            v.get('gid', None) for k, v in admins['groups'].iteritems()])
        dupes = [k for k, v in Counter(gids).items() if v > 1]
        self.assertEqual([], dupes, 'Duplicate group GIDs: %r' % dupes)

if __name__ == '__main__':
    unittest.main()
