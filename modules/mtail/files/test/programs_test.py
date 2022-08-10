#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import unittest
import os
import glob
import re

test_dir = os.path.join(os.path.dirname(__file__))


class ProgramsTest(unittest.TestCase):
    """Run tests across all mtail programs."""

    def setUp(self):
        self.programs = glob.glob(os.path.join(test_dir, "../programs/*.mtail"))
        self.assertNotEqual(self.programs, [], "No mtail programs found!")

    # Histogram buckets must have a -1 bucket to cater for 0 observations
    # https://phabricator.wikimedia.org/T314922
    def testHistogramMinusOneBucket(self):
        for path in self.programs:
            self._has_minus_one_bucket(path)

    def _has_minus_one_bucket(self, path):
        histogram_re = re.compile(r"^\s*histogram\s+")
        buckets_re = re.compile(r"buckets\s+-1\s*,")
        with open(path) as f:
            for num, line in enumerate(f):
                if histogram_re.match(line):
                    self.assertIsNotNone(
                        buckets_re.search(line),
                        f"Histogram at {path}:{num} does not have a -1 bucket",
                    )
