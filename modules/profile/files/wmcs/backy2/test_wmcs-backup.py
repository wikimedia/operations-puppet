#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# pylint: disable=missing-class-docstring,missing-function-docstring
from __future__ import annotations

import importlib
from unittest.mock import patch

wmcs_backup = importlib.import_module("wmcs-backup")


exclude_volumes = {"project_a": ["^temp.*"]}
project_assignments = {"ALLOTHERS": "host_b", "project_a": "test_host"}

dummy_config = wmcs_backup.VolumeBackupsConfig(
    "test-pool",
    "dummy.cfg",
    7,
    exclude_volumes=exclude_volumes,
    project_assignments=project_assignments,
)

dummy_volume_info = {
    "123": {"id": "123", "name": "volume1", "os-vol-tenant-attr:tenant_id": "project_a"},
    "456": {"id": "456", "name": "tempvolume", "os-vol-tenant-attr:tenant_id": "project_a"},
}


class TestWmcsBackup:
    @patch("rbd2backy2.ceph_volumes", return_value=["volume-123", "volume-456"])
    @patch("socket.gethostname", return_value="test_host")
    def test_get_assigned_images(self, mock_ceph_volumes, mock_gethostname):
        volume_backups_state = wmcs_backup.ImageBackupsState(
            config=dummy_config,
            image_backups={},
            images_info=dummy_volume_info,
            image_prefix="volume-",
        )
        result = volume_backups_state.get_assigned_images()
        assert dummy_volume_info["123"] in result, "Volume with ID 123 should be included in result"
        assert (
            dummy_volume_info["456"] not in result
        ), "Volume with ID 456 should not be included because its name matches "
        "the exclude_volumes regex"
