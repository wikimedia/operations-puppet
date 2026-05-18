#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import unittest
import pathlib
import tempfile
import shutil

import deploy

import yaml


class AlertsDeployTest(unittest.TestCase):
    def setUp(self):
        self.alerts_dir = pathlib.Path(tempfile.mkdtemp())
        self.deploy_dir = pathlib.Path(tempfile.mkdtemp())

    def tearDown(self):
        shutil.rmtree(self.alerts_dir.as_posix())
        shutil.rmtree(self.deploy_dir.as_posix())

    def _add_rulefile(self, dir, *args):
        base_dir = self.alerts_dir.joinpath(dir)
        base_dir.mkdir(exist_ok=True)
        for file in args:
            with open(base_dir.joinpath(file), "w") as _:
                pass

    def _add_rulefile_with_tags(self, dir, *args, **kwargs):
        base_dir = self.alerts_dir.joinpath(dir)
        base_dir.mkdir(exist_ok=True)

        for file in args:
            with open(base_dir.joinpath(file), "w") as f:
                for k, v in kwargs["tags"].items():
                    f.write("# {}: {}\n".format(k, v))

    def testSimpleDeploy(self):
        self._add_rulefile("team-foo", "alert1.yaml", "test.yaml", "alert2_test.yaml")
        rulefiles = deploy.all_rulefiles([self.alerts_dir.joinpath("team-foo")])
        deployed_paths = deploy.deploy_rulefiles(
            rulefiles, self.deploy_dir, self.alerts_dir
        )

        outfiles = list(self.deploy_dir.iterdir())

        assert len(deployed_paths) == 2
        assert len(outfiles) == 2
        assert sorted([x.name for x in outfiles]) == [
            "team-foo_alert1.yaml",
            "team-foo_test.yaml",
        ]

    def testTagDeploySimple(self):
        self._add_rulefile("team-foo", "alert-notags.yaml")
        self._add_rulefile_with_tags(
            "team-foo",
            "alert-tags.yaml",
            tags={"deploy-tag": "ok", "deploy-site": "blah"},
        )
        self._add_rulefile_with_tags(
            "team-foo",
            "alert-tagsnotok.yaml",
            tags={"deploy-tag": "notok", "deploy-site": "meh"},
        )

        rulefiles = deploy.all_rulefiles([self.alerts_dir.joinpath("team-foo")])
        rulefiles = deploy.filter_tag(rulefiles, "deploy-tag", "ok", "local")
        deployed_paths = deploy.deploy_rulefiles(
            rulefiles, self.deploy_dir, self.alerts_dir
        )

        outfiles = list(self.deploy_dir.iterdir())

        assert len(deployed_paths) == 2
        assert len(outfiles) == 1
        assert sorted([x.name for x in outfiles]) == [
            "team-foo_alert-tags.yaml",
        ]

    def testTagDeployCombined(self):
        self._add_rulefile("team-foo", "alert-notags.yaml")
        self._add_rulefile_with_tags(
            "team-foo",
            "alert-tags.yaml",
            tags={"deploy-tag": "ok", "deploy-site": "blah"},
        )
        self._add_rulefile_with_tags(
            "team-foo",
            "alert-tagsnotok.yaml",
            tags={"deploy-tag": "notok", "deploy-site": "meh"},
        )

        rulefiles = deploy.all_rulefiles([self.alerts_dir.joinpath("team-foo")])
        rulefiles = deploy.filter_tag(rulefiles, "deploy-tag", "ok", "ok")
        rulefiles = deploy.filter_tag(rulefiles, "deploy-site", "blah", "blah")
        deployed_paths = deploy.deploy_rulefiles(
            rulefiles, self.deploy_dir, self.alerts_dir
        )

        outfiles = list(self.deploy_dir.iterdir())

        assert len(deployed_paths) == 5
        assert len(outfiles) == 2
        assert sorted([x.name for x in outfiles]) == [
            "team-foo_alert-notags.yaml",
            "team-foo_alert-tags.yaml",
        ]

    def testCleanup(self):
        self._add_rulefile("team-foo", "alert1.yaml", "alert2.yaml")
        rulefiles = deploy.all_rulefiles([self.alerts_dir.joinpath("team-foo")])
        deployed_paths = deploy.deploy_rulefiles(
            rulefiles, self.deploy_dir, self.alerts_dir
        )

        with open(self.deploy_dir.joinpath("stray_file"), "w") as _:
            pass

        deploy.cleanup_dir(self.deploy_dir, deployed_paths)

        outfiles = list(self.deploy_dir.iterdir())
        assert sorted([x.name for x in outfiles]) == [
            "team-foo_alert1.yaml",
            "team-foo_alert2.yaml",
        ]


class TagsTest(unittest.TestCase):
    def setUp(self):
        self.path = pathlib.Path(tempfile.mkdtemp())

    def tearDown(self):
        shutil.rmtree(self.path.as_posix())

    def write_text(self, filename, text):
        with open(self.path / filename, "w") as f:
            f.write(text)

    def result_ok(self, files, expected):
        names = [x.name for x in files]
        assert set(names) == set(expected)

    def testTagDefaultValue(self):
        self.write_text("no-tag", "# random header\n\n")
        self.write_text("default-value", "# tag: default\n\n")
        self.write_text("other-value", "# tag:other\n\n")
        self.write_text("ok-value", "# tag:    value\n\n")

        # Materialize the generator, we're going to reuse the list
        files = list(self.path.glob("*"))

        filtered = deploy.filter_tag(files, "tag", "default", "default")
        self.result_ok(filtered, ["no-tag", "default-value"])

        filtered = deploy.filter_tag(files, "tag", "value", "default")
        self.result_ok(filtered, ["ok-value"])

    def testTagPatternMatch(self):
        self.write_text("multiple-values", "# tag: foo, bar,baz\n\n")
        self.write_text("pattern", "# tag:prefix*\n\n")
        self.write_text("multiple-pattern", "# tag: foo, prefix1*, prefix2\n\n")

        # Materialize the generator, we're going to reuse the list
        files = list(self.path.glob("*"))

        filtered = deploy.filter_tag(files, "tag", "bar", "default")
        self.result_ok(filtered, ["multiple-values"])

        filtered = deploy.filter_tag(files, "tag", "prefix1foo", "default")
        self.result_ok(filtered, ["pattern", "multiple-pattern"])

        filtered = deploy.filter_tag(files, "tag", "prefix2", "default")
        self.result_ok(filtered, ["pattern", "multiple-pattern"])

    def testTagNotReadInTrailer(self):
        self.write_text(
            "tag-end", "# header\n\n\nrestof\n\nfile\n# tag: value\ntrailer\n"
        )

        # Materialize the generator, we're going to reuse the list
        files = list(self.path.glob("*"))

        filtered = deploy.filter_tag(files, "tag", "default", "default")
        self.result_ok(filtered, ["tag-end"])

        filtered = deploy.filter_tag(files, "tag", "value", "default")
        self.result_ok(filtered, [])


def _sample_rulefile(summary, description, severity):
    """Return a minimal Prometheus alerting-rule YAML string.

    Annotation values are single-quoted so that '#page' is preserved as a
    literal string value rather than being silently stripped as a YAML comment.
    """
    return (
        "groups:\n"
        "  - name: test\n"
        "    rules:\n"
        "      - alert: TestAlert\n"
        "        expr: up == 0\n"
        "        for: 5m\n"
        "        annotations:\n"
        "          summary: '{summary}'\n"
        "          description: '{description}'\n"
        "        labels:\n"
        "          severity: {severity}\n"
        "          team: sre\n".format(
            summary=summary, description=description, severity=severity
        )
    )


def _page_positions():
    """Return (summary, description, stripped_summary, stripped_description) tuples
    covering #page at the end, middle, and beginning of annotation values."""
    return [
        (
            "Something is wrong #page",
            "Something is very wrong #page",
            "Something is wrong",
            "Something is very wrong",
        ),
        (
            "Something #page is wrong",
            "Something #page is very wrong",
            "Something is wrong",
            "Something is very wrong",
        ),
        (
            "#page Something is wrong",
            "#page Something is very wrong",
            "Something is wrong",
            "Something is very wrong",
        ),
    ]


class PageIsCriticalTransformTest(unittest.TestCase):
    """Tests for the 'page-is-critical' transformation."""

    def test_strips_page_from_summary_and_description(self):
        for summary, description, exp_summary, exp_description in _page_positions():
            with self.subTest(summary=summary):
                content = _sample_rulefile(summary, description, "page")
                result = deploy.apply_transforms(content, ["page-is-critical"])
                data = yaml.safe_load(result)

                rule = data["groups"][0]["rules"][0]
                self.assertEqual(rule["annotations"]["summary"], exp_summary)
                self.assertEqual(rule["annotations"]["description"], exp_description)

    def test_changes_severity_page_to_critical(self):
        for summary, description, _, _ in _page_positions():
            with self.subTest(summary=summary):
                content = _sample_rulefile(summary, description, "page")
                result = deploy.apply_transforms(content, ["page-is-critical"])
                data = yaml.safe_load(result)

                rule = data["groups"][0]["rules"][0]
                self.assertEqual(rule["labels"]["severity"], "critical")

    def test_leaves_non_page_severity_unchanged(self):
        content = _sample_rulefile(
            "Something is wrong",
            "Something is very wrong",
            "warning",
        )
        result = deploy.apply_transforms(content, ["page-is-critical"])
        data = yaml.safe_load(result)

        rule = data["groups"][0]["rules"][0]
        self.assertEqual(rule["labels"]["severity"], "warning")
        self.assertEqual(rule["annotations"]["summary"], "Something is wrong")
        self.assertEqual(rule["annotations"]["description"], "Something is very wrong")

    def test_multiple_rules(self):
        """When there are multiple rules, each should be transformed independently.
        #page is matched regardless of position (end, middle, beginning)."""
        raw = (
            "groups:\n"
            "  - name: test\n"
            "    rules:\n"
            "      - alert: PageAlertEnd\n"
            "        expr: up == 0\n"
            "        for: 5m\n"
            "        annotations:\n"
            "          summary: 'Page me #page'\n"
            "          description: 'Desc #page'\n"
            "        labels:\n"
            "          severity: page\n"
            "      - alert: PageAlertMiddle\n"
            "        expr: up == 0\n"
            "        for: 5m\n"
            "        annotations:\n"
            "          summary: 'Page #page me'\n"
            "          description: '#page Desc'\n"
            "        labels:\n"
            "          severity: page\n"
            "      - alert: WarnAlert\n"
            "        expr: up < 1\n"
            "        for: 10m\n"
            "        annotations:\n"
            "          summary: Just a warning\n"
            "          description: Nothing to page about\n"
            "        labels:\n"
            "          severity: warning\n"
        )
        result = deploy.apply_transforms(raw, ["page-is-critical"])
        data = yaml.safe_load(result)

        rules = data["groups"][0]["rules"]
        # First rule: page -> critical, trailing #page stripped
        self.assertEqual(rules[0]["labels"]["severity"], "critical")
        self.assertEqual(rules[0]["annotations"]["summary"], "Page me")
        self.assertEqual(rules[0]["annotations"]["description"], "Desc")
        # Second rule: page -> critical, mid/leading #page stripped
        self.assertEqual(rules[1]["labels"]["severity"], "critical")
        self.assertEqual(rules[1]["annotations"]["summary"], "Page me")
        self.assertEqual(rules[1]["annotations"]["description"], "Desc")
        # Third rule: unchanged
        self.assertEqual(rules[2]["labels"]["severity"], "warning")
        self.assertEqual(rules[2]["annotations"]["summary"], "Just a warning")

    def test_rule_without_annotations(self):
        """Rules without an annotations key must not cause a KeyError."""
        raw = (
            "groups:\n"
            "  - name: test\n"
            "    rules:\n"
            "      - alert: NoAnnotations\n"
            "        expr: up == 0\n"
            "        labels:\n"
            "          severity: page\n"
        )
        result = deploy.apply_transforms(raw, ["page-is-critical"])
        data = yaml.safe_load(result)

        rule = data["groups"][0]["rules"][0]
        self.assertEqual(rule["labels"]["severity"], "critical")
        self.assertNotIn("annotations", rule)


class PageIsWarningTransformTest(unittest.TestCase):
    """Tests for the 'page-is-warning' transformation."""

    def test_strips_page_from_summary_and_description(self):
        for summary, description, exp_summary, exp_description in _page_positions():
            with self.subTest(summary=summary):
                content = _sample_rulefile(summary, description, "page")
                result = deploy.apply_transforms(content, ["page-is-warning"])
                data = yaml.safe_load(result)

                rule = data["groups"][0]["rules"][0]
                self.assertEqual(rule["annotations"]["summary"], exp_summary)
                self.assertEqual(rule["annotations"]["description"], exp_description)

    def test_changes_severity_page_to_warning(self):
        for summary, description, _, _ in _page_positions():
            with self.subTest(summary=summary):
                content = _sample_rulefile(summary, description, "page")
                result = deploy.apply_transforms(content, ["page-is-warning"])
                data = yaml.safe_load(result)

                rule = data["groups"][0]["rules"][0]
                self.assertEqual(rule["labels"]["severity"], "warning")

    def test_leaves_non_page_severity_unchanged(self):
        content = _sample_rulefile(
            "Something is wrong",
            "Something is very wrong",
            "critical",
        )
        result = deploy.apply_transforms(content, ["page-is-warning"])
        data = yaml.safe_load(result)

        rule = data["groups"][0]["rules"][0]
        self.assertEqual(rule["labels"]["severity"], "critical")
        self.assertEqual(rule["annotations"]["summary"], "Something is wrong")


class ApplyTransformsTest(unittest.TestCase):
    """Tests for apply_transforms error handling."""

    def test_invalid_yaml_returns_content_unchanged(self):
        bad = "groups: [\n  - unclosed"
        result = deploy.apply_transforms(bad, ["page-is-critical"])
        self.assertEqual(result, bad)


class DeployWithTransformsTest(unittest.TestCase):
    """Integration test: deploy with --transform applied."""

    def setUp(self):
        self.alerts_dir = pathlib.Path(tempfile.mkdtemp())
        self.deploy_dir = pathlib.Path(tempfile.mkdtemp())

    def tearDown(self):
        shutil.rmtree(self.alerts_dir.as_posix())
        shutil.rmtree(self.deploy_dir.as_posix())

    def test_deploy_with_page_is_critical_transform(self):
        # Create a rulefile with a paging alert
        team_dir = self.alerts_dir / "team-foo"
        team_dir.mkdir(exist_ok=True)
        rulefile = team_dir / "alert.yaml"
        rulefile.write_text(
            "groups:\n"
            "  - name: test\n"
            "    rules:\n"
            "      - alert: DiskFull\n"
            "        expr: disk_free < 10\n"
            "        for: 5m\n"
            "        annotations:\n"
            "          summary: 'Disk full #page'\n"
            "          description: 'Disk is full #page'\n"
            "        labels:\n"
            "          severity: page\n"
            "          team: sre\n"
        )

        rulefiles = deploy.all_rulefiles([self.alerts_dir / "team-foo"])
        deployed_paths = deploy.deploy_rulefiles(
            rulefiles, self.deploy_dir, self.alerts_dir, transforms=["page-is-critical"]
        )

        assert len(deployed_paths) == 1

        # Read the deployed file and verify the transformation was applied
        deployed_file = self.deploy_dir / "team-foo_alert.yaml"
        deployed_content = deployed_file.read_text(encoding="utf-8")
        data = yaml.safe_load(deployed_content)

        rule = data["groups"][0]["rules"][0]
        self.assertEqual(rule["labels"]["severity"], "critical")
        self.assertEqual(rule["annotations"]["summary"], "Disk full")
        self.assertEqual(rule["annotations"]["description"], "Disk is full")

    def test_deploy_without_transform_unchanged(self):
        # Create a rulefile with a paging alert
        team_dir = self.alerts_dir / "team-foo"
        team_dir.mkdir(exist_ok=True)
        rulefile = team_dir / "alert.yaml"
        rulefile.write_text(
            "groups:\n"
            "  - name: test\n"
            "    rules:\n"
            "      - alert: DiskFull\n"
            "        expr: disk_free < 10\n"
            "        for: 5m\n"
            "        annotations:\n"
            "          summary: 'Disk full #page'\n"
            "          description: 'Disk is full #page'\n"
            "        labels:\n"
            "          severity: page\n"
            "          team: sre\n"
        )

        rulefiles = deploy.all_rulefiles([self.alerts_dir / "team-foo"])
        deployed_paths = deploy.deploy_rulefiles(
            rulefiles, self.deploy_dir, self.alerts_dir
        )

        assert len(deployed_paths) == 1

        # Read the deployed file and verify it's unchanged
        deployed_file = self.deploy_dir / "team-foo_alert.yaml"
        deployed_content = deployed_file.read_text(encoding="utf-8")
        data = yaml.safe_load(deployed_content)

        rule = data["groups"][0]["rules"][0]
        self.assertEqual(rule["labels"]["severity"], "page")
        self.assertEqual(rule["annotations"]["summary"], "Disk full #page")
        self.assertEqual(rule["annotations"]["description"], "Disk is full #page")


if __name__ == "__main__":
    unittest.main()
