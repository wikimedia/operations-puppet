from os import path
import sys
import tempfile
import unittest
from unittest.mock import patch, Mock

sys.path.append("../grid_configurator")
from grid_configurator import grid_configurator

OPENSTACK_MOCK_HOSTS = {
    "exec": ["dummy01", "dummy02", "dummy03"],
    "submit": [
        "toolsbeta-sgecron-0000.toolsbeta.eqiad.wmflabs",
        "toolsbeta-sgebastion-0000.toolsbeta.eqiad.wmflabs",
    ],
}


class GridHostGroupTest(unittest.TestCase):
    @classmethod
    def setupClass(cls):
        cls.conf_object = grid_configurator.GridHostGroup("@dummies")

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_check_exists(self, mock_run):
        mock_run.return_value.returncode = 0
        self.assertTrue(self.conf_object.check_exists())

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_check_exists_when_it_doesnt(self, mock_run):
        mock_run.return_value.returncode = 1
        self.assertFalse(self.conf_object.check_exists())

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_create_new_hostgroup(self, mock_run):
        tmp_dir = tempfile.mkdtemp()
        new_grid_resource = "@dummies"
        mock_run.return_value.returncode = 0
        with open(path.join(tmp_dir, new_grid_resource), "w") as input_file:
            input_file.write(
                """\
group_name              @dummies
hostlist dummy01 dummy02 dummy03
"""
            )

        self.assertTrue(
            self.conf_object.create(path.join(tmp_dir, new_grid_resource), False)
        )

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_update_existing_resource(self, mock_run):
        tmp_dir = tempfile.mkdtemp()
        grid_resource = "@dummies"
        mock_run.return_value.returncode = 0
        mock_run.return_value.stdout = b"""\
group_name              @dummies
hostlist dummy01 dummy03
"""
        with open(path.join(tmp_dir, grid_resource), "w") as input_file:
            input_file.write(
                """\
group_name              @dummies
hostlist dummy01 dummy02 dummy03
"""
            )
        mock_hp = Mock()
        mock_hp.host_set = OPENSTACK_MOCK_HOSTS
        self.assertTrue(
            self.conf_object.compare_and_update(
                path.join(tmp_dir, grid_resource), False, mock_hp
            )
        )

        # Make sure two subprocesses are called, once to get the config
        # and once to modify the resource
        self.assertEqual(mock_run.call_count, 2)

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_compare_existing_resource(self, mock_run):
        tmp_dir = tempfile.mkdtemp()
        grid_resource = "dummy_instance"
        mock_run.return_value.returncode = 0
        mock_run.return_value.stdout = b"""\
group_name              @dummies
hostlist dummy01 dummy02 dummy03
"""
        mock_hp = Mock()
        mock_hp.host_set = OPENSTACK_MOCK_HOSTS
        with open(path.join(tmp_dir, grid_resource), "w") as input_file:
            input_file.write(
                """\
# Look at my file!
group_name              @dummies
hostlist dummy01 dummy02 dummy03
"""
            )

        self.conf_object.compare_and_update(
            path.join(tmp_dir, grid_resource), False, mock_hp
        )

        # If they match, it should only call the subprocess once
        mock_run.assert_called_once_with(
            ["qconf", "-shgrp", "@dummies"],
            stdout=grid_configurator.subprocess.PIPE,
            check=True,
            timeout=60,
        )
