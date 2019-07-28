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


fixtures = os.path.join(os.path.dirname(
    os.path.realpath(__file__)), 'fixtures')


def tempfile_mock(*args, **kwargs):
    my_dir = '/tmp/envoy-build-test'
    os.mkdir(my_dir)
    return my_dir


class TestEnvoyConfig:

    def setup_method(self):
        envoy.logger.setLevel(logging.DEBUG)

    def test_init(self):
        """Test initialization"""
        ep = envoy.EnvoyConfig('/etc/envoy')
        assert ep.config_file == '/etc/envoy/envoy.yaml'
        assert ep.admin_file == '/etc/envoy/admin-config.yaml'

    def test_populate_config_ok(self):
        """Full integration test of reading the config from files"""
        ep = envoy.EnvoyConfig(os.path.join(fixtures, 'good'))
        ep.populate_config()
        # Check that admin gets populated
        assert ep.config['admin']['access_log_path'] == '/tmp/test.log'
        # Check listeners are loaded in order
        resources = ep.config['static_resources']['listeners']
        assert resources[0]['address']['socket_address']['port_value'] == 443
        assert resources[1]['address']['socket_address']['port_value'] == 80

    def test_populate_config_bad(self):
        """Test what happens when the yaml is bad"""
        with pytest.raises(yaml.parser.ParserError):
            ep = envoy.EnvoyConfig(os.path.join(fixtures, 'bad'))
            ep.populate_config()
        with pytest.raises(OSError):
            envoy.EnvoyConfig(fixtures).populate_config()

    @mock.patch('tempfile.mkdtemp')
    def test_verify_good_config(self, mkd):
        mkd.side_effect = tempfile_mock
        ep = envoy.EnvoyConfig(os.path.join(fixtures, 'good'))
        ep.populate_config()
        # Now choose - if envoy is installed, use it to do a proper
        # integration test
        if os.path.isfile('/usr/bin/envoy'):
            assert ep.verify_config()
            # Now let's throw a wrench here
            del ep.config['clusters'][1]
            assert ep.verify_config() is False

        # Now let's verify the calls with some mocking
        with mock.patch('subprocess.check_output') as subp:
            assert ep.verify_config()
            # Now let's simulate failure
            subp.assert_called_with(
                [
                    '/usr/bin/envoy', '-c', '/tmp/envoy-build-test/envoy.yaml',
                    '--mode=verify'
                ]
            )
            subp.side_effect = subprocess.CalledProcessError(
                returncode=2, cmd="foobar", output="that's not valid")
            assert ep.verify_config() is False
