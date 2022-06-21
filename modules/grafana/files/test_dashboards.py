# SPDX-License-Identifier: Apache-2.0
import unittest
import json
import os

test_dir = os.path.join(os.path.dirname(__file__))
dashboards_dir = os.path.join(test_dir, 'dashboards')


class ValidJSONDashboardTest(unittest.TestCase):
    """Make sure dashboards are effectively valid JSON."""

    def load_json(self, path):
        with open(path) as f:
            json.load(f)
        return True

    def testHomeDashboard(self):
        self.load_json(os.path.join(test_dir, 'home.json'))

    def testCustomDashboards(self):
        for name in os.listdir(dashboards_dir):
            dashboard_path = os.path.join(dashboards_dir, name)
            if os.path.isfile(dashboard_path):
                self.load_json(dashboard_path)
