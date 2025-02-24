#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import unittest
from pontoon.rolegroups import RoleGroup, RoleGroups


class TestRoleGroups(unittest.TestCase):

    def setUp(self):
        self.test_data = {
            "__default": {
                "roles": ["pki::multirootca", "puppetdb"],
                "settings": ["pki", "puppetdb"],
            },
            "sd": {"roles": ["pontoon::lb"], "settings": ["sd_cloudvps"]},
            "metrics": {
                "include": ["sd"],
                "roles": ["prometheus", "titan", "grafana"],
                "settings": ["prometheus", "grafana"],
            },
            "alerts": {
                "include": ["sd"],
                "roles": ["alerting_host"],
                "settings": ["alerting_host"],
            },
            "o11y": {
                "include": ["alerts", "metrics"],
                "roles": ["alerting_host"],
                "settings": ["alerting_host"],
            },
        }

        self.role_groups = RoleGroups(self.test_data)

    def test_get_group_includes(self):
        group = self.role_groups.get_group("metrics")
        self.assertSetEqual(
            group.roles,
            {
                "grafana",
                "pki::multirootca",
                "pontoon::lb",
                "prometheus",
                "puppetdb",
                "titan",
            },
        )

    def test_get_group_recursive_includes(self):
        group = self.role_groups.get_group("o11y")
        self.assertSetEqual(
            group.roles,
            {
                "grafana",
                "pki::multirootca",
                "pontoon::lb",
                "prometheus",
                "puppetdb",
                "titan",
                "alerting_host",
            },
        )

    def test_get_group_implicit_includes(self):
        group = self.role_groups.get_group("sd")
        self.assertEqual(group.includes, [])
        self.assertSetEqual(
            group.roles,
            {
                "pki::multirootca",
                "pontoon::lb",
                "puppetdb",
            },
        )

    def test_missing_group(self):
        empty_group = self.role_groups.get_group("nonexistent")
        self.assertEqual(empty_group.roles, set())
        self.assertEqual(empty_group.settings, set())
        self.assertEqual(empty_group.includes, [])


class TestRoleGroup(unittest.TestCase):

    def setUp(self):
        """Set up test RoleGroup instances."""
        self.base_group = RoleGroup(
            name="metrics",
            roles=["prometheus", "grafana"],
            settings=["monitoring"],
            includes=["sd"],
        )

        self.included_group = RoleGroup(
            name="sd", roles=["lb"], settings=["sd_cloudvps"]
        )

    def test_merge(self):
        """Test merging another RoleGroup."""
        self.base_group.merge(self.included_group)

        self.assertSetEqual(self.base_group.roles, {"prometheus", "grafana", "lb"})
        self.assertSetEqual(self.base_group.settings, {"monitoring", "sd_cloudvps"})

    def test_from_dict(self):
        data = {
            "roles": ["alerting_host"],
            "settings": ["alerting"],
            "include": ["metrics"],
        }
        group = RoleGroup.from_dict("alerts", data)

        self.assertEqual(group.name, "alerts")
        self.assertSetEqual(group.roles, {"alerting_host"})
        self.assertSetEqual(group.settings, {"alerting"})
        self.assertEqual(group.includes, ["metrics"])
