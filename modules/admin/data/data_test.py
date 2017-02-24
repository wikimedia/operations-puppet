#!/usr/bin/env python

# 2014 Chase Pettet
# Tests to perform basic validation on data.yaml

from collections import Counter
import os
import unittest
import yaml


class DataTest(unittest.TestCase):
    def testDataDotYaml(self):

        with open(os.path.join(os.path.dirname(__file__), 'data.yaml')) as f:
            admins = yaml.safe_load(f)

        # ensure no two groups uses the same gid
        gids = filter(None, [
            v.get('gid', None) for k, v in admins['groups'].iteritems()])
        dupes = [k for k, v in Counter(gids).items() if v > 1]
        self.assertEqual([], dupes, 'Duplicate group GIDs: %r' % dupes)

if __name__ == '__main__':
    unittest.main()
