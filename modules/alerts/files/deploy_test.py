#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import unittest
import pathlib
import tempfile
import shutil

import deploy


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
