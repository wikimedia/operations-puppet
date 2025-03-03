#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0


import os
import unittest
from unittest.mock import MagicMock, patch

from pontoon import Pontoon


def pontoon_for_rolemap(rolemap, name="test"):
    mock_yaml_load = MagicMock(return_value=rolemap)

    with patch("builtins.open", MagicMock()), patch(
        "pontoon.base.YAML", return_value=MagicMock(load=mock_yaml_load)
    ):
        pontoon = Pontoon(name=name)

    return pontoon


class TestPontoon(unittest.TestCase):
    def test_base_rolemap(self):
        p = pontoon_for_rolemap({"puppetserver::pontoon": ["foo.bar", "bar.baz"]})
        self.assertEqual(p.server_fqdn, "foo.bar")
        self.assertEqual(
            p.role_variables(),
            {
                "__hosts_for_role_puppetserver__pontoon": ["foo.bar", "bar.baz"],
                "__master_for_role_puppetserver__pontoon": "foo.bar",
            },
        )
        self.assertEqual(
            p.host_map(),
            {
                "foo.bar": "puppetserver::pontoon",
                "bar.baz": "puppetserver::pontoon",
            },
        )

        p = pontoon_for_rolemap({"bogus": ["foo.bar", "bar.baz"]})
        self.assertIsNone(p.server_fqdn)

    def test_host_map(self):
        p = pontoon_for_rolemap({"foo": ["bar1", "bar2"]})
        self.assertEqual(p.hosts_for_role("foo"), ["bar1", "bar2"])

    def test_pontoon_init(self):
        mock_open = MagicMock()
        mock_yaml_load = MagicMock(return_value={"role": "user"})

        with patch("builtins.open", mock_open), patch(
            "pontoon.base.YAML", return_value=MagicMock(load=mock_yaml_load)
        ):
            pontoon = Pontoon(name="example")

        self.assertEqual(pontoon.name, "example")
        self.assertEqual(pontoon.base_path, ".")
        self.assertEqual(pontoon.rolemap, {"role": "user"})
        self.assertEqual(pontoon.stack_path, "./example")

        mock_open.assert_called_once_with(
            os.path.join(pontoon.stack_path, "rolemap.yaml")
        )
        mock_yaml_load.assert_called_once_with(mock_open().__enter__())

    def test_config_vars(self):
        p = pontoon_for_rolemap({"foo": ["bar1", "bar2"]})
        p.set_config_value("host_prefix", "bar")
        self.assertEqual(p.get_config_value("host_prefix"), "bar")

        with self.assertRaises(KeyError):
            p.get_config_value("nonexist")
