"""Tests es_exporter configs."""
import unittest
import configparser
import os
import glob
import json


class ValidateEsExporterConfig(unittest.TestCase):
    pass


def make_test(config, section):
    def run(self):
        # raises ValueError
        config.getfloat(section, 'QueryIntervalSecs', fallback=15)
        config.getfloat(section, 'QueryTimeoutSecs', fallback=10)
        # raises json.decoder.JSONDecodeError
        if section != 'DEFAULT':
            json.loads(config.get(section, 'QueryJson'))
        # raises AssertionError
        self.assertIn(config.get(section, 'QueryOnError', fallback='drop'),
                      ['preserve', 'drop', 'zero'])
        self.assertIn(config.get(section, 'QueryOnMissing', fallback='drop'),
                      ['preserve', 'drop', 'zero'])
    return run


test_dir = os.path.join(os.path.dirname(__file__))
config_dir_file_pattern = os.path.join(test_dir, '..', 'es_exporter', '*.cfg')
config_dir_sorted_files = sorted(glob.glob(config_dir_file_pattern))

# Attempt to parse all the cfg files.  configparser.ParsingError will fail to proceed.
config = configparser.ConfigParser()
config.read(config_dir_sorted_files)

# Dynamically build up tests based on configuration sections available.
for section in config.sections() + ['DEFAULT']:
    the_test = make_test(config, section)
    the_test.__name__ = 'test_{}'.format(section)
    setattr(ValidateEsExporterConfig, the_test.__name__, the_test)
