#!/usr/bin/env python

import os
import unittest


class RoleTest(unittest.TestCase):

    def test_no_not_subdirs(self):
        paths = os.listdir(os.path.join(
            os.path.dirname(os.path.dirname(__file__)), 'manifests'))
        bad = [x for x in paths if x.endswith('.pp')]
        self.assertEquals(
            bad, [],
            'There should be no *.pp files in modules/role/manifests/,' +
            ' they need to be in subdirectories')

if __name__ == '__main__':
    unittest.main()
