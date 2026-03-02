#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
import importlib.util
from pathlib import Path
from click.testing import CliRunner

# load the script as a module since the filename contains a hyphen
spec = importlib.util.spec_from_file_location(
    "slothslos_flatten",
    Path(__file__).parent / "slothslos_flatten.py",
)
slothslos = importlib.util.module_from_spec(spec)
spec.loader.exec_module(slothslos)


def test_get_all_rulefiles(tmp_path):
    # create files in nested dirs: .yaml, .yml, and other files
    (tmp_path / "a").mkdir()
    (tmp_path / "a" / "one.yaml").write_text("x")
    (tmp_path / "b").mkdir()
    (tmp_path / "b" / "two.yml").write_text("y")
    (tmp_path / "b" / "skip.txt").write_text("z")

    found = slothslos.get_all_rulefiles(tmp_path)
    # should find both .yaml and .yml
    assert (tmp_path / "a" / "one.yaml") in found
    assert (tmp_path / "b" / "two.yml") in found
    assert (tmp_path / "b" / "skip.txt") not in found
    assert all(p.suffix in [".yaml", ".yml"] for p in found)


def test_get_all_rulefiles_with_exclude_pattern(tmp_path):
    # create files that match an exclude pattern
    (tmp_path / "rules").mkdir()
    (tmp_path / "rules" / "active.yaml").write_text("x")
    (tmp_path / "rules" / "deprecated_rule.yaml").write_text("y")
    (tmp_path / "rules" / "old_file.yaml").write_text("z")

    # exclude files matching "deprecated"
    found = slothslos.get_all_rulefiles(
        tmp_path, exclude_pattern=r"deprecated"
    )
    # only active.yaml should be found
    assert (tmp_path / "rules" / "active.yaml") in found
    assert (tmp_path / "rules" / "deprecated_rule.yaml") not in found
    assert (tmp_path / "rules" / "old_file.yaml") in found
    assert len(found) == 2


def test_flattened_copy(tmp_path):
    src = tmp_path / "src"
    dst = tmp_path / "dst"
    # build tree with nested dirs
    (src / "dir").mkdir(parents=True)
    (src / "dir" / "file.yaml").write_text("data")
    (src / "other.yaml").write_text("data2")

    copied = slothslos.flattened_copy(src, dst)
    # verify that copy returns correct paths
    assert len(copied) == 2
    # compute expected flattened names using same logic as production
    expected = []
    for f in (src / "dir" / "file.yaml", src / "other.yaml"):
        prefix = f.relative_to(src).parent.as_posix().replace("/", "_")
        expected.append(dst / f"{prefix}_{f.name}")
    for p in expected:
        assert p.exists(), f"expected {p} to exist"


def test_flattened_copy_with_exclude_pattern(tmp_path):
    src = tmp_path / "src"
    dst = tmp_path / "dst"
    # build tree with nested dirs
    (src / "rules").mkdir(parents=True)
    (src / "rules" / "active.yaml").write_text("data1")
    (src / "rules" / "deprecated.yaml").write_text("data2")
    (src / "other.yml").write_text("data3")

    # copy with pattern to exclude deprecated files
    copied = slothslos.flattened_copy(src, dst, exclude_pattern=r"deprecated")
    # should have 2 files, not 3
    assert len(copied) == 2
    # check the correct files were copied
    assert any("active.yaml" in str(p) for p in copied)
    assert any("other.yaml" in str(p) for p in copied)
    assert not any("deprecated" in str(p) for p in copied)


def test_main_success(tmp_path):
    runner = CliRunner()

    # create a manifests directory with nested yaml files
    manifests_dir = tmp_path / "manifests"
    (manifests_dir / "sub").mkdir(parents=True)
    (manifests_dir / "sub" / "a.yaml").write_text("rule1")
    (manifests_dir / "b.yml").write_text("rule2")

    flatten = tmp_path / "flatten"

    result = runner.invoke(
        slothslos.main,
        ["--manifests-dir", str(manifests_dir), "--flatten-dir", str(flatten)],
    )
    assert result.exit_code == 0
    # verify files were copied and flattened
    # files in subdirs get prefix (sub_a.yaml), root files get dot prefix (._b.yml)
    assert (flatten / "sub_a.yaml").exists()
    assert (flatten / "._b.yaml").exists()


def test_main_with_exclude_pattern(tmp_path):
    runner = CliRunner()

    # create a manifests directory with some files to exclude
    manifests_dir = tmp_path / "manifests"
    (manifests_dir / "rules").mkdir(parents=True)
    (manifests_dir / "rules" / "active.yaml").write_text("rule1")
    (manifests_dir / "rules" / "deprecated.yaml").write_text("rule2")

    flatten = tmp_path / "flatten"

    result = runner.invoke(
        slothslos.main,
        [
            "--manifests-dir",
            str(manifests_dir),
            "--flatten-dir",
            str(flatten),
            "--exclude-pattern",
            r"deprecated",
        ],
    )
    assert result.exit_code == 0
    # verify only non-deprecated files were copied
    assert any(f.name.endswith("active.yaml") for f in flatten.rglob("*"))
    assert not any("deprecated" in f.name for f in flatten.rglob("*"))
