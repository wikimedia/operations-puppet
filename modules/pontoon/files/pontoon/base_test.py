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


def test_pontoon_initialization():
    # Mock the file reading operation
    mock_open = MagicMock()
    mock_yaml_load = MagicMock(
        return_value={"role": "user"}
    )  # Provide a sample rolemap for testing

    with patch("builtins.open", mock_open), patch(
        "pontoon.base.YAML", return_value=MagicMock(load=mock_yaml_load)
    ):
        pontoon = Pontoon(name="example")

    # Assertions
    assert pontoon.name == "example"
    assert pontoon.base_path == "."
    assert pontoon.rolemap == {"role": "user"}

    # Check that the mock_open was called with the correct file path
    mock_open.assert_called_once_with(os.path.join(pontoon.stack_path, "rolemap.yaml"))

    # Check that the mock_yaml_load was called with the opened file
    mock_yaml_load.assert_called_once_with(mock_open().__enter__())


def test_host_map():
    p = pontoon_for_rolemap({"foo": ['bar1', 'bar2']})
    assert p.hosts_for_role('foo') == ['bar1', 'bar2']