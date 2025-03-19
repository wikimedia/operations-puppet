#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import unittest

from pontoon.host import Filter, Host


class TestHostFilter(unittest.TestCase):
    def test_host_repr(self):
        h = Host("a.example.com", "role::foo")
        self.assertEqual(repr(h), "Host(fqdn='a.example.com', role='role::foo')")

    def test_host_equality(self):
        h1 = Host("a.example.com", "role::foo")
        h2 = Host("a.example.com", "role::foo")
        h3 = Host("b.example.com", "role::foo")
        h4 = Host("a.example.com", "role::bar")

        self.assertEqual(h1, h2)
        self.assertNotEqual(h1, h3)
        self.assertNotEqual(h1, h4)

    def test_host_hashing(self):
        h1 = Host("a.example.com", "role::foo")
        h2 = Host("a.example.com", "role::foo")
        h3 = Host("b.example.com", "role::foo")

        hosts = {h1, h2, h3}
        self.assertEqual(len(hosts), 2)

    def test_filter_multiple_conditions(self):
        hosts = [
            Host("a.example.com", "role::foo"),
            Host("b.example.com", "role::bar"),
            Host("c.example.com", "role::foo"),
        ]

        f = Filter(hosts)
        self.assertEqual(len(f), 3)

        f = f.apply(Filter.by_role("role::foo"))
        self.assertEqual(len(f), 2)

        f = f.apply(Filter.by_fqdn("a*"))
        self.assertEqual(len(f), 1)

        self.assertEqual(list(f)[0].fqdn, "a.example.com")

    def test_filter_any_condition(self):
        hosts = [
            Host("a.example.com", "role::foo"),
            Host("b.example.com", "role::bar"),
            Host("c.example.com", "role::baz"),
        ]

        f = Filter(hosts)
        f = f.apply(
            Filter.any(Filter.by_role("role::foo"), Filter.by_role("role::bar"))
        )
        self.assertEqual(len(f), 2)

    def test_filter_not_condition(self):
        hosts = [
            Host("a.example.com", "role::foo"),
            Host("b.example.com", "role::bar"),
            Host("c.example.com", "role::baz"),
        ]

        f = Filter(hosts)
        f = f.apply(
            Filter.not_(Filter.by_role("role::foo")),
        )
        self.assertEqual(len(f), 2)
        for h in f:
            self.assertNotEqual(h.role, "role::foo")

    def test_filter_by_fqdn_exact(self):
        hosts = [
            Host("a.example.com", "role::foo"),
            Host("b.example.com", "role::bar"),
            Host("c.example.com", "role::baz"),
        ]

        f = Filter(hosts)
        f = f.apply(Filter.by_fqdn("b.example.com"))
        self.assertEqual(len(f), 1)
        self.assertEqual(list(f)[0].fqdn, "b.example.com")

    def test_filter_by_fqdn_pattern(self):
        hosts = [
            Host("a.example.com", "role::foo"),
            Host("b.example.com", "role::bar"),
            Host("c.example.com", "role::baz"),
        ]

        f = Filter(hosts)
        f = f.apply(Filter.by_fqdn("*.example.com"))
        self.assertEqual(len(f), 3)

        f = Filter(hosts)
        f = f.apply(Filter.by_fqdn("a*"))
        self.assertEqual(len(f), 1)
        self.assertEqual(list(f)[0].fqdn, "a.example.com")
