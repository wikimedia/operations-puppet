import os
import sys
import tempfile
import unittest
from unittest.mock import patch
from unittest.mock import MagicMock

sys.path.append("../grid_configurator")
from grid_configurator import grid_configurator


OPENSTACK_MOCK_HOSTS = {
    "exec": [
        "toolsbeta-sgeexec-0000.toolsbeta.eqiad.wmflabs",
        "toolsbeta-sgeexec-0002.toolsbeta.eqiad.wmflabs",
    ],
    "submit": [
        "toolsbeta-sgecron-0000.toolsbeta.eqiad.wmflabs",
        "toolsbeta-sgebastion-0000.toolsbeta.eqiad.wmflabs",
    ],
}

CURRENT_HOST_CONF1 = b"""\
hostname              toolsbeta-sgeexec-0000.toolsbeta.eqiad.wmflabs
complex_values        h_vmem=3G,slots=32,release=stretch
load_scaling          NONE
user_lists            NONE
xuser_lists           NONE
projects              NONE
xprojects             NONE
usage_scaling         NONE
report_variables      NONE
"""

CURRENT_HOST_CONF2 = b"""\
hostname              toolsbeta-sgeexec-0002.toolsbeta.eqiad.wmflabs
complex_values        h_vmem=3G,slots=32,release=stretch
load_scaling          NONE
user_lists            NONE
xuser_lists           NONE
projects              NONE
xprojects             NONE
usage_scaling         NONE
report_variables      NONE
"""


class HostProcessorTest(unittest.TestCase):
    @classmethod
    @patch("grid_configurator.grid_configurator.HostProcessor._get_regions")
    @patch("grid_configurator.grid_configurator.HostProcessor._hosts")
    @patch("grid_configurator.grid_configurator.session.Session", autospec=True)
    def setupClass(cls, mock_get_regions, mock_get_servers, mock_session):
        tmp_dir = tempfile.mkdtemp()
        os.mkdir(os.path.join(tmp_dir, "exechosts"))
        HostProcessorTest.exec_dir = os.path.join(tmp_dir, "exechosts")
        existing_exec_host_one = "toolsbeta-sgeexec-0000.toolsbeta.eqiad.wmflabs"
        with open(
            os.path.join(HostProcessorTest.exec_dir, existing_exec_host_one), "w"
        ) as input_file:
            input_file.write(
                """\
hostname              toolsbeta-sgeexec-0000.toolsbeta.eqiad.wmflabs
complex_values        h_vmem=3G,slots=32,release=stretch
load_scaling          NONE
user_lists            NONE
xuser_lists           NONE
projects              NONE
xprojects             NONE
usage_scaling         NONE
report_variables      NONE
"""
            )
        existing_exec_host_two = "toolsbeta-sgeexec-0002.toolsbeta.eqiad.wmflabs"
        with open(
            os.path.join(HostProcessorTest.exec_dir, existing_exec_host_two), "w"
        ) as input_file:
            input_file.write(
                """\
hostname              toolsbeta-sgeexec-0002.toolsbeta.eqiad.wmflabs
complex_values        h_vmem=3G,slots=32,release=stretch
load_scaling          NONE
user_lists            NONE
xuser_lists           NONE
projects              NONE
xprojects             NONE
usage_scaling         NONE
report_variables      NONE
"""
            )
        mock_get_regions.return_value = ["region"]
        mock_get_servers.return_value = OPENSTACK_MOCK_HOSTS
        cls.host_proc_object = grid_configurator.HostProcessor(
            "http://dummycontrol1003.wikimedia.org:5000/v3",
            "not-a-password",
            grid_configurator.GRID_HOST_PREFIX,
            True,
            tmp_dir,
            grid_configurator.GRID_HOST_TYPE,
        )

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_run_updates_with_new_host(self, mock_run):
        GRID_MOCK_EXEC_HOSTS = b"""\
toolsbeta-sgeexec-0000.toolsbeta.eqiad.wmflabs
"""
        GRID_MOCK_SUBMIT_HOSTS = b"""\
toolsbeta-sgebastion-0000.toolsbeta.eqiad.wmflabs
toolsbeta-sgecron-0000.toolsbeta.eqiad.wmflabs
"""
        mock_run.side_effect = [
            MagicMock(stdout=GRID_MOCK_EXEC_HOSTS, returncode=0),
            MagicMock(stdout=CURRENT_HOST_CONF1, returncode=0),
            MagicMock(stdout=CURRENT_HOST_CONF2, returncode=0),
            MagicMock(stdout=GRID_MOCK_SUBMIT_HOSTS, returncode=0),
        ]
        self.host_proc_object.run_updates(False, grid_configurator.GRID_HOST_TYPE)
        mock_run.assert_any_call(
            [
                "qconf",
                "-Ae",
                os.path.join(
                    self.__class__.exec_dir,
                    "toolsbeta-sgeexec-0002.toolsbeta.eqiad.wmflabs",
                ),
            ],
            stdout=grid_configurator.subprocess.PIPE,
            check=True,
            timeout=60,
        )
        self.assertEqual(mock_run.call_count, 4)

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_run_updates_with_deleted_host(self, mock_run):
        GRID_MOCK_EXEC_HOSTS = b"""\
toolsbeta-sgeexec-0000.toolsbeta.eqiad.wmflabs
toolsbeta-sgeexec-0002.toolsbeta.eqiad.wmflabs
toolsbeta-sgeexec-0001.toolsbeta.eqiad.wmflabs
"""
        GRID_MOCK_SUBMIT_HOSTS = b"""\
toolsbeta-sgebastion-0000.toolsbeta.eqiad.wmflabs
toolsbeta-sgecron-0000.toolsbeta.eqiad.wmflabs
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
            ["qconf", "-de", "toolsbeta-sgeexec-0001.toolsbeta.eqiad.wmflabs"],
            stdout=grid_configurator.subprocess.PIPE,
            check=True,
            timeout=60,
        )
        self.assertEqual(mock_run.call_count, 5)

    @patch("grid_configurator.grid_configurator.subprocess.run")
    def test_run_updates_with_same_hosts(self, mock_run):

        GRID_MOCK_EXEC_HOSTS = b"""\
toolsbeta-sgeexec-0000.toolsbeta.eqiad.wmflabs
toolsbeta-sgeexec-0002.toolsbeta.eqiad.wmflabs
"""
        GRID_MOCK_SUBMIT_HOSTS = b"""\
toolsbeta-sgebastion-0000.toolsbeta.eqiad.wmflabs
toolsbeta-sgecron-0000.toolsbeta.eqiad.wmflabs
"""
        mock_run.side_effect = [
            MagicMock(stdout=GRID_MOCK_EXEC_HOSTS, returncode=0),
            MagicMock(stdout=CURRENT_HOST_CONF1, returncode=0),
            MagicMock(stdout=CURRENT_HOST_CONF2, returncode=0),
            MagicMock(stdout=GRID_MOCK_SUBMIT_HOSTS, returncode=0),
        ]
        self.host_proc_object.run_updates(False, grid_configurator.GRID_HOST_TYPE)
        self.assertEqual(mock_run.call_count, 4)
