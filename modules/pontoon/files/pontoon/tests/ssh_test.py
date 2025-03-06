#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

from unittest.mock import patch
import subprocess
import pontoon.ssh as ssh


class TestSshBash:
    @patch("subprocess.run")
    def test_bash_success(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["ssh", "test.example.com", "bash", "-c", "echo test"],
            returncode=0,
            stdout="test output",
            stderr="",
        )

        result = ssh.bash("test.example.com", "echo test")

        mock_run.assert_called_once()
        assert result.returncode == 0
        assert result.stdout == "test output"
        assert result.stderr == ""

    @patch("subprocess.run")
    def test_bash_failure(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["ssh", "test.example.com", "bash", "-c", "exit 1"],
            returncode=1,
            stdout="",
            stderr="error output",
        )

        result = ssh.bash("test.example.com", "exit 1")

        assert result.returncode == 1
        assert result.stdout == ""
        assert result.stderr == "error output"

    @patch("subprocess.run")
    def test_bash_with_args(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["ssh", "test.example.com", "bash", "-c", "ls -l"],
            returncode=0,
            stdout="file list",
            stderr="",
        )

        result = ssh.bash("test.example.com", "ls -l", capture_output=True, text=True)

        mock_run.assert_called_once()
        assert result.stdout == "file list"
