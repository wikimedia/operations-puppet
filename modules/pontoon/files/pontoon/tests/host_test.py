#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import unittest

from pontoon.host import Host, Filter


class TestHostFilter(unittest.TestCase):

    def setUp(self):
        self.hosts = [
            Host("server1.example.com", "web"),
            Host("server2.example.com", "db"),
            Host("app1.example.org", "app"),
            Host("server3.example.com", "web"),
            Host("db1.example.org", "db"),
        ]
        # same as first host in self.hosts
        self.duplicate_host = Host("server1.example.com", "web")
        self.filter = Filter(self.hosts)

    def test_host_repr(self):
        host = Host("test.example.com", "test-role")
        self.assertEqual(repr(host), "Host(fqdn='test.example.com', role='test-role')")

    def test_filter_by_fqdn_exact(self):
        filtered = self.filter.apply(Filter.by_fqdn("server1.example.com"))
        self.assertEqual(len(filtered), 1)
        self.assertEqual(filtered._hosts[0].fqdn, "server1.example.com")

    def test_filter_by_fqdn_pattern(self):
        filtered = self.filter.apply(Filter.by_fqdn("server*.example.com"))
        self.assertEqual(len(filtered), 3)

    def test_filter_multiple_conditions(self):
        filtered = self.filter.apply(
            Filter.by_fqdn("server*.example.com"), Filter.by_role("web")
        )
        self.assertEqual(len(filtered), 2)

    def test_filter_any_condition(self):
        filtered = self.filter.apply(
            Filter.any(Filter.by_fqdn("server1.example.com"), Filter.by_role("db"))
        )
        self.assertEqual(len(filtered), 3)

    def test_filter_not_condition(self):
        filtered = self.filter.apply(Filter.not_(Filter.by_fqdn("server1.example.com")))
        self.assertEqual(len(filtered), 4)

    def test_host_equality(self):
        self.assertEqual(self.hosts[0], self.duplicate_host)
        self.assertNotEqual(self.hosts[1], self.duplicate_host)

    def test_host_hashing(self):
        self.assertEqual(hash(self.hosts[0]), hash(self.duplicate_host))
        self.assertNotEqual(hash(self.hosts[1]), hash(self.duplicate_host))
