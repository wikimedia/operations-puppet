#!/usr/bin/python3

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

    def testSimpleDeploy(self):
        self._add_rulefile("team-foo", "alert1.yaml", "alert2.yaml")
        rulefiles = deploy.all_rulefiles([self.alerts_dir.joinpath("team-foo")])
        deployed_paths = deploy.deploy_rulefiles(
            rulefiles, self.deploy_dir, self.alerts_dir
        )

        outfiles = list(self.deploy_dir.iterdir())

        assert len(deployed_paths) == 2
        assert len(outfiles) == 2
        assert sorted([x.name for x in outfiles]) == [
            "team-foo_alert1.yaml",
            "team-foo_alert2.yaml",
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
