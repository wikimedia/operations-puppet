# SPDX-License-Identifier: Apache-2.0
from os import path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.append("../grid_configurator")
from grid_configurator import grid_configurator


class GridConfigInitTest(unittest.TestCase):
    def test_grid_config_init(self):
        grid_configurator.GridConfig(
            "dummy",
            "dummy_intance",
            ["/bin/echo", "add"],
            ["/bin/echo", "mod"],
            ["/bin/echo", "del"],
            ["/bin/echo", "get"],
        )


class GridConfigUsageTest(unittest.TestCase):
    def setUp(self):
        self.conf_object = grid_configurator.GridConfig(
            "dummy",
            "dummy_intance",
            ["qconf", "-Aq"],
            ["/bin/echo", "mod"],
            ["/bin/echo", "del"],
            ["/bin/echo", "get"],
        )

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_check_exists(self, mock_run):
        mock_run.return_value.returncode = 0
        self.assertTrue(self.conf_object.check_exists())

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_check_exists_when_it_doesnt(self, mock_run):
        mock_run.return_value.returncode = 1
        self.assertFalse(self.conf_object.check_exists())

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_create_new_resource(self, mock_run):
        tmp_dir = tempfile.mkdtemp()
        new_grid_resource = "magic-queue"
        mock_run.return_value.returncode = 0
        with open(path.join(tmp_dir, new_grid_resource), "w") as input_file:
            input_file.write(
                """\
qname                   magic-queue
glurp                   FLURP
broke                   VERY
"""
            )

        self.assertTrue(
            self.conf_object.create(path.join(tmp_dir, new_grid_resource), False)
        )

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_update_existing_resource(self, mock_run):
        tmp_dir = tempfile.mkdtemp()
        grid_resource = "magic-queue"
        mock_run.return_value.returncode = 0
        mock_run.return_value.stdout = b"""\
qname                   magic-queue
glurp                   GLURP
broke                   VERY
"""
        with open(path.join(tmp_dir, grid_resource), "w") as input_file:
            input_file.write(
                """\
qname                   magic-queue
glurp                   FLURP
broke                   VERY
"""
            )

        self.assertTrue(
            self.conf_object.compare_and_update(
                path.join(tmp_dir, grid_resource), False
            )
        )

        # Make sure two subprocesses are called, once to get the config
        # and once to modify the resource
        self.assertEqual(mock_run.call_count, 2)

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_compare_existing_resource(self, mock_run):
        tmp_dir = tempfile.mkdtemp()
        grid_resource = "dummy_intance"
        mock_run.return_value.returncode = 0
        mock_run.return_value.stdout = b"""\
qname                   magic-queue
glurp                   FLURP
broke                   VERY
"""
        with open(path.join(tmp_dir, grid_resource), "w") as input_file:
            input_file.write(
                """\
# Look at my file!
qname                   magic-queue
glurp                   FLURP
broke                   VERY
"""
            )

        self.conf_object.compare_and_update(path.join(tmp_dir, grid_resource), False)

        # If they match, it should only call the subprocess once
        mock_run.assert_called_once_with(
            "/bin/echo get dummy_intance",
            capture_output=True,
            shell=True,
            timeout=60,
        )
