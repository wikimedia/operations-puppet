#!/usr/bin/env python

# 2014 Chase Pettet
# Tests to perform basic validation on data.yaml

from collections import Counter
import itertools
import os
import unittest
import yaml

from data_admin import flatten_members


class UnitTest(unittest.TestCase):

    def test_flatten_members(self):
        assert flatten_members([]) == []
        assert flatten_members(['hashar']) == ['hashar']
        assert flatten_members(['a1', 'b1']) == ['a1', 'b1']

        # Nesting related
        assert flatten_members([['nest1', 'nest2']]) == ['nest1', 'nest2']
        assert flatten_members(['element', ['nest1']]) == ['element', 'nest1']
        assert flatten_members(['element', ['nest1', 'nest2']]) \
            == ['element', 'nest1', 'nest2']

        # Uniqueness
        assert flatten_members(['nest1', 'nest1']) == ['nest1']
        assert flatten_members(['nest1', ['nest1']]) == ['nest1']
        assert flatten_members(['nest1', ['nest1', 'nest1']]) == ['nest1']

        # Ordering

        expected = [1, 4, 3, 7, 9, 2, 6]
        assert flatten_members([1, 4, 3, 7, 9, 2, 6]) == expected
        assert flatten_members([[1, 4, 3], [7, 9, 2, 6]]) == expected


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
            lambda u: flatten_members(u['members']), admins['groups'].values()
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
            'Users assigned that do not exist'
        )

        # ensure no two groups uses the same gid
        gids = filter(None, [
            v.get('gid', None) for k, v in admins['groups'].iteritems()])
        dupes = [k for k, v in Counter(gids).items() if v > 1]
        self.assertEqual([], dupes, 'Duplicate group GIDs')

if __name__ == '__main__':
    unittest.main()
