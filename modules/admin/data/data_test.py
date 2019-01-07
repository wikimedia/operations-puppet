#!/usr/bin/env python

# 2014 Chase Pettet
# Tests to perform basic validation on data.yaml

from collections import Counter
import os
import unittest
import yaml


class DataTest(unittest.TestCase):

    admins = None

    @classmethod
    def setUpClass(cls):
        with open(os.path.join(os.path.dirname(__file__), 'data.yaml')) as f:
            cls.admins = yaml.safe_load(f)

    def testGroupGIDSAreUniques(self):
        # ensure no two groups uses the same gid
        gids = filter(None, [
            v.get('gid', None) for k, v in self.admins['groups'].iteritems()])
        dupes = [k for k, v in Counter(gids).items() if v > 1]
        self.assertEqual([], dupes, 'Duplicate group GIDs: %r' % dupes)

    def testAbsentMembers(self):
        absent_members = set(self.admins['groups']['absent']['members'])
        absentees = set([
            username
            for username, val in self.admins['users'].items()
            if val['ensure'] == 'absent'
            ])
        self.maxDiff = None
        self.longMessage = True
        self.assertSetEqual(
            absent_members,
            absentees,
            'Absent users are both in "absent" group (first set)'
            'and in marked "ensure: absent" (second set)')


if __name__ == '__main__':
    unittest.main()
