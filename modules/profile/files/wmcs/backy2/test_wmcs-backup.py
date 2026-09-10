#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# pylint: disable=missing-class-docstring,missing-function-docstring
from __future__ import annotations

import importlib
import os
import re
import tempfile
import time
from datetime import datetime, timedelta
from pathlib import Path
from unittest.mock import patch

import pytest

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


class TestBackupMetrics:
    """Tests for the ``wmcs-backup metrics`` subcommand and its helpers."""

    def _make_entries(self) -> list:
        now = datetime.now()

        def entry(name: str, age_seconds: int, size_bytes: int, valid: bool):
            return wmcs_backup.BackupEntry(
                date=now - timedelta(seconds=age_seconds),
                name=name,
                snapshot_name=name,
                size_mb=size_bytes // (1024 * 1024),
                size_bytes=size_bytes,
                uid="uid",
                valid=valid,
                protected=False,
                tags=[],
                expire=datetime.min,
            )

        return [
            # instance (name ends with _disk): 2 valid, 1 invalid
            entry("vm1_disk", 3 * 3600, 1000, True),
            entry("vm2_disk", 1 * 3600, 2000, True),
            entry("vm3_disk", 2 * 3600, 500, False),
            # image (bare name: not volume- and not *_disk)
            entry("image-abc", 2 * 3600, 3000, True),
            # volume (name starts with volume-)
            entry("volume-vol1", 4 * 3600, 4000, True),
        ]

    @staticmethod
    def _parse_prom(text: str) -> dict:
        """Parse prometheus text exposition into {(name, frozenset(labels)): value}.

        Also validates that every sample line is well-formed.
        """
        metrics: dict = {}
        for line in text.splitlines():
            if not line or line.startswith("#"):
                continue
            m = re.match(r"^(\w+)(?:\{([^}]*)\})? (-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)$", line)
            assert m is not None, f"unparseable prometheus line: {line!r}"
            name = m.group(1)
            labels: frozenset = frozenset()
            if m.group(2):
                pairs = []
                for part in m.group(2).split(","):
                    k, v = part.split("=")
                    pairs.append((k, v.strip('"')))
                labels = frozenset(pairs)
            metrics[(name, labels)] = float(m.group(3))
        return metrics

    def _metrics(self, entries) -> dict:
        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, "wmcs-backups.prom")
            with patch.object(wmcs_backup, "get_backups", return_value=entries):
                rc = wmcs_backup.collect_backup_metrics(outfile=Path(out))
            assert rc == 0
            with open(out) as fh:
                return self._parse_prom(fh.read())

    @pytest.fixture
    def metrics(self) -> dict:
        return self._metrics(self._make_entries())

    def test_backup_kind(self) -> None:
        assert wmcs_backup._backup_kind("volume-foo") == "volume"
        assert wmcs_backup._backup_kind("volumefoo") == "image"
        assert wmcs_backup._backup_kind("vm1_disk") == "instance"
        assert wmcs_backup._backup_kind("vm1") == "image"
        assert wmcs_backup._backup_kind("") == "image"

    @pytest.mark.parametrize(
        "kind, entries, valid, size_bytes, distinct, newest_age, oldest_age",
        [
            # (kind, total, valid, total_size, distinct_valid, newest_age_s, oldest_age_s)
            ("instance", 3, 2, 3500, 2, 3600, 10800),
            ("image", 1, 1, 3000, 1, 7200, 7200),
            ("volume", 1, 1, 4000, 1, 14400, 14400),
        ],
    )
    def test_collect_backup_metrics(
        self,
        metrics,
        kind,
        entries,
        valid,
        size_bytes,
        distinct,
        newest_age,
        oldest_age,
    ) -> None:
        def val(name: str, **labels) -> float:
            key = (name, frozenset(labels.items()))
            assert key in metrics, f"missing metric {name} {labels}"
            return metrics[key]

        # collector succeeded
        assert val("wmcs_backup_collector_error") == 0

        now = time.time()
        assert val("wmcs_backup_entries", kind=kind) == entries
        assert val("wmcs_backup_entries_valid", kind=kind) == valid
        assert val("wmcs_backup_entries_invalid", kind=kind) == entries - valid
        assert val("wmcs_backup_size_bytes", kind=kind) == size_bytes
        assert val("wmcs_backup_distinct_backed_up", kind=kind) == distinct
        assert abs(val("wmcs_backup_newest_timestamp_seconds", kind=kind) - (now - newest_age)) < 5
        assert abs(val("wmcs_backup_oldest_timestamp_seconds", kind=kind) - (now - oldest_age)) < 5

    def test_no_all_kind(self, metrics) -> None:
        # The "all" kind is intentionally NOT exported: summing across the `kind`
        # labels would double-count (all == instance + image + volume).
        all_labels = frozenset({"kind": "all"}.items())
        assert not any(labels == all_labels for (_, labels) in metrics)

    def test_collect_backup_metrics_get_backups_error(self) -> None:
        def boom():
            raise RuntimeError("boom")

        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, "wmcs-backups.prom")
            with patch.object(wmcs_backup, "get_backups", side_effect=boom):
                rc = wmcs_backup.collect_backup_metrics(outfile=Path(out))
            assert rc == 0
            with open(out) as fh:
                text = fh.read()
        metrics = self._parse_prom(text)
        assert metrics[("wmcs_backup_collector_error", frozenset())] == 1
        assert metrics[("wmcs_backup_entries", frozenset({"kind": "instance"}.items()))] == 0
