# SPDX-License-Identifier: Apache-2.0
import os
import sys
import tempfile
import unittest
from unittest.mock import patch
from unittest.mock import MagicMock

sys.path.append("../grid_configurator")
from grid_configurator import grid_configurator

# openstack will always report the newer domain
OPENSTACK_MOCK_HOSTS = {
    "exec": [
        "toolsbeta-sgeexec-0000.toolsbeta.eqiad1.wikimedia.cloud",
        "toolsbeta-sgeexec-0002.toolsbeta.eqiad1.wikimedia.cloud",
    ],
    "submit": [
        "toolsbeta-sgebastion-0000.toolsbeta.eqiad1.wikimedia.cloud",
        "toolsbeta-sgecron-0000.toolsbeta.eqiad1.wikimedia.cloud",
    ],
}

# an already-configured host using the legacy domain
CURRENT_HOST_CONF1 = b"""\
hostname              toolsbeta-sgeexec-0000.toolsbeta.eqiad1.wikimedia.cloud
complex_values        h_vmem=3G,slots=32,release=stretch
load_scaling          NONE
user_lists            NONE
xuser_lists           NONE
projects              NONE
xprojects             NONE
usage_scaling         NONE
report_variables      NONE
"""

# an already-configured host using the new domain
CURRENT_HOST_CONF2 = b"""\
hostname              toolsbeta-sgeexec-0002.toolsbeta.eqiad1.wikimedia.cloud
complex_values        h_vmem=3G,slots=32,release=buster
load_scaling          NONE
user_lists            NONE
xuser_lists           NONE
projects              NONE
xprojects             NONE
usage_scaling         NONE
report_variables      NONE
"""


class HostProcessorTest(unittest.TestCase):
    @patch("grid_configurator.grid_configurator.HostProcessor._get_regions")
    @patch("grid_configurator.grid_configurator.HostProcessor._hosts")
    @patch("grid_configurator.grid_configurator.session.Session", autospec=True)
    def setUp(self, mock_get_regions, mock_get_servers, mock_session):
        tmp_dir = tempfile.mkdtemp()
        os.mkdir(os.path.join(tmp_dir, "exechosts"))
        self.exec_dir = os.path.join(tmp_dir, "exechosts")
        existing_exec_host_one = "toolsbeta-sgeexec-0000.toolsbeta.eqiad1.wikimedia.cloud"
        with open(
            os.path.join(self.exec_dir, existing_exec_host_one), "w"
        ) as input_file:
            input_file.write(CURRENT_HOST_CONF1.decode("utf-8"))
        existing_exec_host_two = "toolsbeta-sgeexec-0002.toolsbeta.eqiad1.wikimedia.cloud"
        with open(
            os.path.join(self.exec_dir, existing_exec_host_two), "w"
        ) as input_file:
            input_file.write(CURRENT_HOST_CONF2.decode("utf-8"))
        mock_get_regions.return_value = ["eqiad1-r"]
        mock_get_servers.return_value = OPENSTACK_MOCK_HOSTS
        self.host_proc_object = grid_configurator.HostProcessor(
            "https://openstack.someregion.eqiad1.wikimediacloud.org:25000/v3",
            "not-a-password",
            grid_configurator.GRID_HOST_PREFIX,
            True,
            tmp_dir,  # this is config_dir, the temp file
            tmp_dir,  # this is grid_root: we don't really care, nothing here is checking it
            grid_configurator.GRID_HOST_TYPE,
        )

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_run_updates_with_new_host(self, mock_run):
        GRID_MOCK_EXEC_HOSTS = b"""\
toolsbeta-sgeexec-0000.toolsbeta.eqiad1.wikimedia.cloud
"""
        GRID_MOCK_SUBMIT_HOSTS = b"""\
toolsbeta-sgebastion-0000.toolsbeta.eqiad1.wikimedia.cloud
toolsbeta-sgecron-0000.toolsbeta.eqiad1.wikimedia.cloud
"""
        mock_run.side_effect = [
            MagicMock(stdout=GRID_MOCK_EXEC_HOSTS, returncode=0),
            MagicMock(stdout=CURRENT_HOST_CONF1, returncode=0),
            MagicMock(stdout=CURRENT_HOST_CONF2, returncode=0),
            MagicMock(stdout=GRID_MOCK_SUBMIT_HOSTS, returncode=0),
        ]
        self.host_proc_object.run_updates(False, grid_configurator.GRID_HOST_TYPE)
        path = os.path.join(
            self.exec_dir,
            "toolsbeta-sgeexec-0002.toolsbeta.eqiad1.wikimedia.cloud"
        )
        mock_run.assert_any_call(
            "qconf -Ae {}".format(path),
            capture_output=True,
            shell=True,
            timeout=60,
        )
        self.assertEqual(mock_run.call_count, 4)

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_run_updates_with_deleted_host(self, mock_run):
        GRID_MOCK_EXEC_HOSTS = b"""\
toolsbeta-sgeexec-0000.toolsbeta.eqiad1.wikimedia.cloud
toolsbeta-sgeexec-0002.toolsbeta.eqiad1.wikimedia.cloud
toolsbeta-sgeexec-0001.toolsbeta.eqiad1.wikimedia.cloud
"""
        GRID_MOCK_SUBMIT_HOSTS = b"""\
toolsbeta-sgebastion-0000.toolsbeta.eqiad1.wikimedia.cloud
toolsbeta-sgecron-0000.toolsbeta.eqiad1.wikimedia.cloud
"""
        mock_run.side_effect = [
            MagicMock(stdout=GRID_MOCK_EXEC_HOSTS, returncode=0),
            MagicMock(stdout=CURRENT_HOST_CONF1, returncode=0),
            MagicMock(stdout=CURRENT_HOST_CONF2, returncode=0),
            MagicMock(stdout=b"", returncode=0),
            MagicMock(stdout=GRID_MOCK_SUBMIT_HOSTS, returncode=0),
        ]
        self.host_proc_object.run_updates(False, grid_configurator.GRID_HOST_TYPE)
        mock_run.assert_any_call(
            "qconf -de toolsbeta-sgeexec-0001.toolsbeta.eqiad1.wikimedia.cloud",
            capture_output=True,
            shell=True,
            timeout=60,
        )
        self.assertEqual(mock_run.call_count, 5)

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_run_updates_with_same_hosts(self, mock_run):

        GRID_MOCK_EXEC_HOSTS = b"""\
toolsbeta-sgeexec-0000.toolsbeta.eqiad1.wikimedia.cloud
toolsbeta-sgeexec-0002.toolsbeta.eqiad1.wikimedia.cloud
"""
        GRID_MOCK_SUBMIT_HOSTS = b"""\
toolsbeta-sgebastion-0000.toolsbeta.eqiad1.wikimedia.cloud
toolsbeta-sgecron-0000.toolsbeta.eqiad1.wikimedia.cloud
"""
        mock_run.side_effect = [
            MagicMock(stdout=GRID_MOCK_EXEC_HOSTS, returncode=0),
            MagicMock(stdout=CURRENT_HOST_CONF1, returncode=0),
            MagicMock(stdout=CURRENT_HOST_CONF2, returncode=0),
            MagicMock(stdout=GRID_MOCK_SUBMIT_HOSTS, returncode=0),
        ]
        self.host_proc_object.run_updates(False, grid_configurator.GRID_HOST_TYPE)
        self.assertEqual(mock_run.call_count, 4)
