#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import unittest
from unittest.mock import MagicMock

from pontoon.host import Filter, Host
from pontoon.cloudvps import CloudHost, CloudVPS
from pontoon.controller import Controller


class TestCloudHost(unittest.TestCase):
    def test_cloudhost_functionality(self):
        """Test that CloudHost works with all Host functionality"""
        host = Host("a.example.com", "role::foo")
        cloud_host = CloudHost("a.example.com", "buster", "g1-small", "role::foo")

        # Test equality works across types
        self.assertEqual(host, cloud_host)

        # Test basic properties
        self.assertEqual(cloud_host.fqdn, "a.example.com")
        self.assertEqual(cloud_host.role, "role::foo")
        self.assertEqual(cloud_host.image, "buster")
        self.assertEqual(cloud_host.flavor, "g1-small")

    def test_filter_cloudhost(self):
        """Test that Filter works with CloudHost correctly"""
        hosts = [
            CloudHost("a.example.com", "bullseye", "g1-small", "role::foo"),
            CloudHost("b.example.com", "buster", "g2-medium", "role::bar"),
            CloudHost("c.example.com", "bullseye", "g3-large", "role::baz"),
        ]

        # Test filtering by role
        f = Filter(hosts)
        f = f.apply(Filter.by_role("role::foo"))
        self.assertEqual(len(f), 1)
        self.assertEqual(list(f)[0].fqdn, "a.example.com")

        # Test filtering by image
        f = Filter(hosts)
        f = f.apply(CloudVPS.by_image("bullseye"))
        self.assertEqual(len(f), 2)
        self.assertEqual(
            sorted([h.fqdn for h in f]), ["a.example.com", "c.example.com"]
        )

        # Test filtering by flavor
        f = Filter(hosts)
        f = f.apply(CloudVPS.by_flavor("g*-medium"))
        self.assertEqual(len(f), 1)
        self.assertEqual(list(f)[0].fqdn, "b.example.com")

        # Test combined filters
        f = Filter(hosts)
        f = f.apply(
            Filter.any(CloudVPS.by_image("bullseye"), CloudVPS.by_flavor("g2-medium"))
        )
        self.assertEqual(len(f), 3)  # All hosts match

        # Test complex filter combination
        f = Filter(hosts)
        f = f.apply(
            Filter.any(Filter.by_role("role::foo"), Filter.by_role("role::bar")),
            Filter.not_(CloudVPS.by_flavor("g3-large")),
        )
        self.assertEqual(len(f), 2)
        self.assertEqual(
            sorted([h.fqdn for h in f]), ["a.example.com", "b.example.com"]
        )


class TestControllerRoleFiltering(unittest.TestCase):
    def setUp(self):
        # Create mocks that we'll use in each test
        self.pontoon_mock = MagicMock()
        self.cloud_mock = MagicMock()
        self.controller = Controller(self.pontoon_mock, self.cloud_mock)

        # Set up test data
        self.cloud_hosts = [
            CloudHost("a.example.com", "bullseye", "g1-small", "role::foo"),
            CloudHost("b.example.com", "buster", "g2-medium", "role::bar"),
            CloudHost("c.example.com", "bullseye", "g3-large", "role::foo"),
            CloudHost("d.example.com", "buster", "g2-medium", "role::baz"),
        ]

        # Mock methods
        self.cloud_mock.list_hosts.return_value = self.cloud_hosts

    def test_filter_logic(self):
        """Test that the filter logic works correctly.

        This tests the actual filtering functionality directly to ensure
        the AND logic between role and pattern.
        """
        # Create mock cloud hosts
        cloud_hosts = [
            CloudHost("a.example.com", "bullseye", "g1-small", "role::foo"),
            CloudHost("b.example.com", "buster", "g2-medium", "role::bar"),
            CloudHost("c.example.com", "bullseye", "g3-large", "role::foo"),
            CloudHost("d.example.com", "buster", "g2-medium", "role::baz"),
        ]

        # Apply filters directly as done in _filter_scope_hosts
        hosts = Filter(cloud_hosts)

        # Apply role filter
        hosts = hosts.apply(Filter.by_role("role::foo"))

        # Verify role filtering works
        self.assertEqual(len(hosts), 2)
        self.assertEqual(
            sorted([h.fqdn for h in hosts]), ["a.example.com", "c.example.com"]
        )

        # Apply pattern filter
        hosts = hosts.apply(Filter.by_fqdn("a*"))

        # Verify combined role and pattern filtering
        self.assertEqual(len(hosts), 1)
        self.assertEqual(list(hosts)[0].fqdn, "a.example.com")
