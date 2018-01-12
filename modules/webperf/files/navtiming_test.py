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
    # When passing a 'msg' to assert methods, display that in
    # addition to the value diff, not instead of the diff.
    longMessage = True

    def flatten(self, values):
        for value in values:
            if isinstance(value, list):
                for subvalue in self.flatten(value):
                    yield subvalue
            else:
                yield value

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
        with open(fixture_path) as fixture_file:
            cases = yaml.safe_load(fixture_file)
            for key, case in cases.items():
                if key == 'templates':
                    continue
                if isinstance(case['input'], list):
                    messages = case['input']
                else:
                    # Wrap in list if input is just one event
                    messages = list([case['input']])
                actual = []
                # print "---", key # debug
                for meta in messages:
                    f = navtiming.handlers.get(meta['schema'])
                    assert f is not None
                    for stat in f(meta):
                        # print stat # debug
                        actual.append(stat)
                # print "" # debug
                self.assertItemsEqual(
                    actual,
                    self.flatten(case['expect']),
                    key
                )


if __name__ == '__main__':
    unittest.main(verbosity=2)
