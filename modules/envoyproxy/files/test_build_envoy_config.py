# SPDX-License-Identifier: Apache-2.0
import logging
import os
import subprocess

try:
    from unittest import mock
except ImportError:
    import mock

import yaml

import pytest

import build_envoy_config as envoy


fixtures = os.path.join(os.path.dirname(os.path.realpath(__file__)), "fixtures")


def tempfile_mock(*args, **kwargs):
    my_dir = "/tmp/envoy-build-test"
    os.mkdir(my_dir)
    return my_dir


class TestEnvoyConfig:
    def setup_method(self):
        envoy.logger.setLevel(logging.DEBUG)

    def test_init(self):
        """Test initialization"""
        ep = envoy.EnvoyConfig("/etc/envoy")
        assert ep.config_file == "/etc/envoy/envoy.yaml"
        assert ep.admin_file == "/etc/envoy/admin-config.yaml"
        assert ep.runtime_file == "/etc/envoy/runtime.yaml"

    def test_populate_config_ok(self):
        """Full integration test of reading the config from files"""
        ep = envoy.EnvoyConfig(os.path.join(fixtures, "good"))
        ep.populate_config()
        # Check that admin gets populated
        assert ep.config["admin"]["access_log_path"] == "/tmp/test.log"
        # Check listeners are loaded in order
        resources = ep.config["static_resources"]["listeners"]
        assert resources[0]["address"]["socket_address"]["port_value"] == 443
        assert resources[1]["address"]["socket_address"]["port_value"] == 80
        # Check that runtime layers are populated in order
        static_layer = ep.config["layered_runtime"]["layers"][0]["static_layer"]
        assert static_layer == {"health_check": {"min_interval": 10}}
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
            del ep.config["clusters"][1]
            assert ep.verify_config() is False

        # Now let's verify the calls with some mocking
        with mock.patch("subprocess.check_output") as subp:
            assert ep.verify_config()
            # Now let's simulate failure
            subp.assert_called_with(
                [
                    "sudo",
                    "-u",
                    "envoy",
                    "/usr/bin/envoy",
                    "-c",
                    "/tmp/.envoyconfig/envoy.yaml",
                    "--mode validate",
                ]
            )
            subp.side_effect = subprocess.CalledProcessError(
                returncode=2, cmd="foobar", output="that's not valid"
            )
            assert ep.verify_config() is False
