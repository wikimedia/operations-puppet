# SPDX-License-Identifier: Apache-2.0
import logging
import os
import shutil
import subprocess
from pathlib import Path
from unittest import mock

import build_envoy_config as envoy
import pytest
import yaml

fixtures = os.path.join(os.path.dirname(os.path.realpath(__file__)), "fixtures")


class TestEnvoyConfig:
    def setup_method(self):
        envoy.logger.setLevel(logging.DEBUG)
        tmpdir = Path("/tmp/.envoyconfig")
        if not tmpdir.is_dir():
            os.mkdir(tmpdir, 0o755)
        for fixture in Path(fixtures).iterdir():
            if fixture.is_file():
                shutil.copy(fixture, tmpdir / fixture.name)

    def test_init(self):
        """Test initialization"""
        ep = envoy.EnvoyConfig("/etc/envoy")
        assert ep.config_file == "/etc/envoy/envoy.yaml"
        assert ep.admin_file == "/etc/envoy/admin-config.yaml"
        assert ep.runtime_file == "/etc/envoy/runtime.yaml"

    def test_populate_config_good(self):
        """Full integration test of reading the config from files"""
        ep = envoy.EnvoyConfig(os.path.join(fixtures, "good"))
        ep.populate_config()
        # Check that admin gets populated
        assert ep.config["admin"]["access_log"]["typed_config"]["path"] == "/tmp/test.log"
        # Check listeners are loaded in order
        resources = ep.config["static_resources"]["listeners"]
        assert resources[0]["address"]["socket_address"]["port_value"] == 443
        assert resources[1]["address"]["socket_address"]["port_value"] == 80
        # Check that runtime layers are populated in order
        static_layer_0 = ep.config["layered_runtime"]["layers"][0]["static_layer"]
        assert static_layer_0 == {"overload": {"global_downstream_max_connections": 50000}}
        static_layer_1 = ep.config["layered_runtime"]["layers"][1]["static_layer"]
        assert static_layer_1 == {"health_check": {"min_interval": 10}}
        assert ep.config["layered_runtime"]["layers"][2]["admin_layer"] == {}

    def test_populate_config_good_no_runtime(self):
        """Full integration test without additional runtime config"""
        ep = envoy.EnvoyConfig(os.path.join(fixtures, "good_no_runtime"))
        ep.populate_config()
        # Check that the default runtime config is populated
        static_layer_0 = ep.config["layered_runtime"]["layers"][0]["static_layer"]
        assert static_layer_0 == {"overload": {"global_downstream_max_connections": 50000}}
        assert ep.config["layered_runtime"]["layers"][1]["admin_layer"] == {}

    def test_populate_config_bad(self):
        """Test what happens when the yaml is bad"""
        with pytest.raises(yaml.parser.ParserError):
            ep = envoy.EnvoyConfig(os.path.join(fixtures, "bad"))
            ep.populate_config()
        with pytest.raises(OSError):
            envoy.EnvoyConfig(fixtures).populate_config()

    def test_verify_good_config(self):
        ep = envoy.EnvoyConfig(os.path.join(fixtures, "good"))
        ep.populate_config()
        # Now choose - if envoy is installed, use it to do a proper
        # integration test
        if os.path.isfile("/usr/bin/envoy"):
            assert ep.verify_config()
            # Now let's throw a wrench here
            del ep.config["static_resources"]["clusters"][1]
            assert ep.verify_config() is False

        # Now let's verify the calls with some mocking
        with mock.patch("subprocess.check_output") as subp, mock.patch(
            "os.geteuid"
        ) as eiud:
            assert ep.verify_config()
            # Now let's simulate failure
            cmd = [
                "/usr/bin/envoy",
                "-c",
                "/tmp/.envoyconfig/envoy.yaml",
                "--mode validate",
            ]
            subp.assert_called_with(cmd)

            # Become root
            eiud.return_value = 0
            subp.side_effect = subprocess.CalledProcessError(
                returncode=2, cmd="foobar", output="that's not valid"
            )
            assert ep.verify_config() is False
            subp.assert_called_with(["sudo", "-u", "envoy"] + cmd)
