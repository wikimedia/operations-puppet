#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import unittest
from io import StringIO
from unittest.mock import MagicMock, patch

import pontoon_wait_puppet


class TestPuppetAgentStats(unittest.TestCase):
    @patch("subprocess.Popen")
    def test_puppet_agent_stats(self, mock_popen):
        """Test parsing of Puppet agent metrics."""
        mock_metrics = (
            b"puppet_agent_enabled 1",
            b"puppet_agent_resources_changed 5",
            b"puppet_agent_resources_total 100",
            b"# ignoreme",
            b"metric_labels{foo=\"bar\"} 9",
        )
        mock_process = MagicMock()
        mock_process.communicate.return_value = (
            b"\n".join(mock_metrics),
            b"",
        )
        mock_process.returncode = 0
        mock_popen.return_value = mock_process

        expected_stats = {
            "puppet_agent_enabled": 1.0,
            "puppet_agent_resources_changed": 5.0,
            "puppet_agent_resources_total": 100.0,
            "metric_labels{foo=\"bar\"}": 9.0,
        }

        self.assertEqual(pontoon_wait_puppet.puppet_agent_stats(), expected_stats)


class TestWaitPuppet(unittest.TestCase):
    @patch("pontoon_wait_puppet.puppet_agent_stats")
    @patch("pontoon_wait_puppet.subs.popen")
    def test_wait_puppet_success(self, mock_popen, mock_puppet_agent_stats):
        """Test successful Puppet run with acceptable resource change percentage."""
        mock_process = MagicMock()
        mock_process.wait.return_value = 0  # Simulating a successful Puppet run
        mock_popen.return_value = mock_process

        mock_puppet_agent_stats.return_value = {
            "puppet_agent_enabled": 1,
            "puppet_agent_resources_changed": 2,
            "puppet_agent_resources_total": 100,
        }

        with patch("sys.stderr", new_callable=StringIO) as mock_stderr:
            result = pontoon_wait_puppet.wait_puppet(
                timeout=10, resource_change_max_pct=5, retry_sleep=1
            )

        self.assertEqual(result, 0)
        self.assertIn("Puppet agent converged", mock_stderr.getvalue())

    @patch("pontoon_wait_puppet.puppet_agent_stats")
    @patch("pontoon_wait_puppet.subs.popen")
    def test_wait_puppet_failure_timeout(self, mock_popen, mock_puppet_agent_stats):
        """Test Puppet run failure due to timeout."""
        mock_process = MagicMock()
        mock_process.returncode = pontoon_wait_puppet.TIMEOUT_REACHED_RETURNCODE
        mock_popen.return_value = mock_process

        with patch("sys.stderr", new_callable=StringIO) as mock_stderr:
            result = pontoon_wait_puppet.wait_puppet(
                timeout=5, resource_change_max_pct=5, retry_sleep=1
            )

        self.assertEqual(result, 1)
        self.assertIn("Puppet run timed out, exiting.", mock_stderr.getvalue())

    @patch("pontoon_wait_puppet.puppet_agent_stats")
    @patch("pontoon_wait_puppet.subs.popen")
    def test_wait_puppet_too_many_changes(self, mock_popen, mock_puppet_agent_stats):
        """Test when too many resources change, requiring retries."""
        mock_process = MagicMock()
        mock_process.wait.return_value = 0  # Simulate a successful Puppet run
        mock_popen.return_value = mock_process

        # First iteration has too many changes, second iteration meets the criteria
        mock_puppet_agent_stats.side_effect = [
            {
                "puppet_agent_enabled": 1,
                "puppet_agent_resources_changed": 20,
                "puppet_agent_resources_total": 100,
            },
            {
                "puppet_agent_enabled": 1,
                "puppet_agent_resources_changed": 2,
                "puppet_agent_resources_total": 100,
            },
        ]

        with patch("sys.stderr", new_callable=StringIO) as mock_stderr:
            result = pontoon_wait_puppet.wait_puppet(
                timeout=10, resource_change_max_pct=5, retry_sleep=1
            )

        self.assertEqual(result, 0)
        self.assertIn("Too many resources changed", mock_stderr.getvalue())
        self.assertIn("Puppet agent converged", mock_stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
