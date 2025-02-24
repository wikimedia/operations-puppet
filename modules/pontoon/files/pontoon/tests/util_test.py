#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import unittest
from unittest.mock import patch
import subprocess
from pontoon.util import ssh_bash


class TestSshBash(unittest.TestCase):
    @patch("subprocess.run")
    def test_ssh_bash_success(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["ssh", "test.example.com", "bash", "-c", "echo test"],
            returncode=0,
            stdout="test output",
            stderr="",
        )

        result = ssh_bash("test.example.com", "echo test")

        mock_run.assert_called_once_with(
            [
                "ssh",
                "-o",
                "BatchMode=yes",
                "-o",
                "ConnectTimeout=6",
                "test.example.com",
                "bash",
                "-c",
                "'echo test'",
            ],
        )
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "test output")
        self.assertEqual(result.stderr, "")

    @patch("subprocess.run")
    def test_ssh_bash_failure(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["ssh", "test.example.com", "bash", "-c", "exit 1"],
            returncode=1,
            stdout="",
            stderr="error output",
        )

        result = ssh_bash("test.example.com", "exit 1")

        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "error output")

    @patch("subprocess.run")
    def test_ssh_bash_with_args(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["ssh", "test.example.com", "bash", "-c", "ls -l"],
            returncode=0,
            stdout="file list",
            stderr="",
        )

        result = ssh_bash("test.example.com", "ls -l", capture_output=True, text=True)

        mock_run.assert_called_once_with(
            [
                "ssh",
                "-o",
                "BatchMode=yes",
                "-o",
                "ConnectTimeout=6",
                "test.example.com",
                "bash",
                "-c",
                "'ls -l'",
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.stdout, "file list")
