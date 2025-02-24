#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import os
from unittest.mock import MagicMock, patch
from pontoon import Pontoon


def pontoon_for_rolemap(rolemap, name="test"):
    mock_yaml_load = MagicMock(return_value=rolemap)

    with patch("builtins.open", MagicMock()), patch(
        "pontoon.base.YAML", return_value=MagicMock(load=mock_yaml_load)
    ):
        pontoon = Pontoon(name=name)

    return pontoon


def test_base_rolemap():
    p = pontoon_for_rolemap({"puppetserver::pontoon": ["foo.bar", "bar.baz"]})
    assert p.server_fqdn == "foo.bar"
    assert p.role_variables() == {
        "__hosts_for_role_puppetserver__pontoon": ["foo.bar", "bar.baz"],
        "__master_for_role_puppetserver__pontoon": "foo.bar",
    }
    assert p.host_map() == {
        "foo.bar": "puppetserver::pontoon",
        "bar.baz": "puppetserver::pontoon",
    }

    p = pontoon_for_rolemap({"bogus": ["foo.bar", "bar.baz"]})
    assert p.server_fqdn is None


def test_host_map():
    p = pontoon_for_rolemap({"foo": ["bar1", "bar2"]})
    assert p.hosts_for_role("foo") == ["bar1", "bar2"]


def test_pontoon_init():
    mock_open = MagicMock()
    mock_yaml_load = MagicMock(return_value={"role": "user"})

    with patch("builtins.open", mock_open), patch(
        "pontoon.base.YAML", return_value=MagicMock(load=mock_yaml_load)
    ):
        pontoon = Pontoon(name="example")

    assert pontoon.name == "example"
    assert pontoon.base_path == "."
    assert pontoon.rolemap == {"role": "user"}
    assert pontoon.stack_path == "./example"

    mock_open.assert_called_once_with(os.path.join(pontoon.stack_path, "rolemap.yaml"))

    mock_yaml_load.assert_called_once_with(mock_open().__enter__())
