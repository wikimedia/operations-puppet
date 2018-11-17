# import subprocess
import sys
import unittest
from unittest.mock import patch
from unittest.mock import MagicMock

sys.path.append("../grid_configurator")
from grid_configurator import grid_configurator


OPENSTACK_MOCK_HOSTS = {
    "exec": ["toolsbeta-sgeexec-0000", "toolsbeta-sgeexec-0002"],
    "submit": ["toolsbeta-sgecron-0000", "toolsbeta-sgebastion-0000"],
}


class HostProcessorTest(unittest.TestCase):
    @classmethod
    @patch("grid_configurator.grid_configurator.HostProcessor._get_regions")
    @patch("grid_configurator.grid_configurator.HostProcessor._hosts")
    @patch("grid_configurator.grid_configurator.session.Session", autospec=True)
    def setupClass(cls, mock_get_regions, mock_get_servers, mock_session):
        mock_get_regions.return_value = ["region"]
        mock_get_servers.return_value = OPENSTACK_MOCK_HOSTS
        cls.host_proc_object = grid_configurator.HostProcessor(
            "http://dummycontrol1003.wikimedia.org:5000/v3",
            "not-a-password",
            grid_configurator.GRID_HOST_TYPES,
            True,
        )

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_run_updates_with_new_host(self, mock_run):
        GRID_MOCK_EXEC_HOSTS = b"""\
toolsbeta-sgeexec-0000
"""
        GRID_MOCK_SUBMIT_HOSTS = b"""\
toolsbeta-sgebastion-0000
toolsbeta-sgecron-0000
"""
        mock_run.side_effect = [
            MagicMock(stdout=GRID_MOCK_EXEC_HOSTS, returncode=0),
            MagicMock(stdout="", returncode=0),
            MagicMock(stdout=GRID_MOCK_SUBMIT_HOSTS, returncode=0),
        ]
        self.host_proc_object.run_updates(False, grid_configurator.GRID_HOST_TYPES)
        mock_run.mock_calls[1].assert_called_with(
            ["qconf", "-ae", "toolsbeta-sgeexec-0002.toolsbeta.eqiad.wmflabs"],
            stdout=grid_configurator.subprocess.PIPE,
            check=True,
            timeout=60,
        )
        self.assertEqual(mock_run.call_count, 3)

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_run_updates_with_deleted_host(self, mock_run):
        GRID_MOCK_EXEC_HOSTS = b"""\
toolsbeta-sgeexec-0000
toolsbeta-sgeexec-0002
toolsbeta-sgeexec-0001
"""
        GRID_MOCK_SUBMIT_HOSTS = b"""\
toolsbeta-sgebastion-0000
toolsbeta-sgecron-0000
"""
        mock_run.side_effect = [
            MagicMock(stdout=GRID_MOCK_EXEC_HOSTS, returncode=0),
            MagicMock(stdout="", returncode=0),
            MagicMock(stdout=GRID_MOCK_SUBMIT_HOSTS, returncode=0),
        ]
        self.host_proc_object.run_updates(False, grid_configurator.GRID_HOST_TYPES)
        mock_run.mock_calls[1].assert_called_with(
            ["qconf", "-de", "toolsbeta-sgeexec-0002.toolsbeta.eqiad.wmflabs"],
            stdout=grid_configurator.subprocess.PIPE,
            check=True,
            timeout=60,
        )
        self.assertEqual(mock_run.call_count, 3)

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_run_updates_with_same_hosts(self, mock_run):
        GRID_MOCK_EXEC_HOSTS = b"""\
toolsbeta-sgeexec-0000
toolsbeta-sgeexec-0002
"""
        GRID_MOCK_SUBMIT_HOSTS = b"""\
toolsbeta-sgebastion-0000
toolsbeta-sgecron-0000
"""
        mock_run.side_effect = [
            MagicMock(stdout=GRID_MOCK_EXEC_HOSTS, returncode=0),
            MagicMock(stdout=GRID_MOCK_SUBMIT_HOSTS, returncode=0),
        ]
        self.host_proc_object.run_updates(False, grid_configurator.GRID_HOST_TYPES)
        self.assertEqual(mock_run.call_count, 2)
