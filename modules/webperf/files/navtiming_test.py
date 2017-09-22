#!/usr/bin/env python

import unittest
import yaml

import navtiming


# ##### Tests ######
# To run:
#   python -m unittest -v navtiming_test
# Or:
#   python navtiming_test.py
#
class TestNavTiming(unittest.TestCase):
    def test_parse_ua(self):
        with open('navtiming_ua_data.yaml') as file:
            data = yaml.safe_load(file)
            for case in data:
                expect = tuple(case.split('.'))
                uas = data.get(case)
                for ua in uas:
                    self.assertEqual(
                        navtiming.parse_ua(ua),
                        expect
                    )

    def test_handlers(self):
        with open('navtiming_fixture.yaml') as fixture_file:
            fixture = yaml.safe_load(fixture_file)
            actual = []
            for meta in fixture:
                f = navtiming.handlers.get(meta['schema'])
                assert f is not None
                for stat in f(meta):
                    actual.append(stat)
            with open('navtiming_expected.txt') as expected_file:
                self.assertItemsEqual(
                    actual,
                    expected_file.read().splitlines()
                )


if __name__ == '__main__':
    unittest.main(verbosity=2)
