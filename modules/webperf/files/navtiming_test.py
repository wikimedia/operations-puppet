#!/usr/bin/env python

import unittest
import yaml
import os

import navtiming


# ##### Tests ######
# To run:
#   python -m unittest -v navtiming_test
# Or:
#   python navtiming_test.py
#
class TestNavTiming(unittest.TestCase):
    def test_parse_ua(self):
        data_path = os.path.join(os.path.dirname(__file__), 'navtiming_ua_data.yaml')
        with open(data_path) as data_file:
            data = yaml.safe_load(data_file)
            for case in data:
                expect = tuple(case.split('.'))
                uas = data.get(case)
                for ua in uas:
                    self.assertEqual(
                        navtiming.parse_ua(ua),
                        expect
                    )

    def test_handlers(self):
        fixture_path = os.path.join(os.path.dirname(__file__), 'navtiming_fixture.yaml')
        expected_path = os.path.join(os.path.dirname(__file__), 'navtiming_expected.txt')
        with open(fixture_path) as fixture_file:
            fixture = yaml.safe_load(fixture_file)
            actual = []
            for meta in fixture:
                f = navtiming.handlers.get(meta['schema'])
                assert f is not None
                for stat in f(meta):
                    actual.append(stat)
            with open(expected_path) as expected_file:
                self.assertItemsEqual(
                    actual,
                    expected_file.read().splitlines()
                )


if __name__ == '__main__':
    unittest.main(verbosity=2)
