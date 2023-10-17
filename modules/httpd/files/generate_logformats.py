#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Utility to generate JSON LogFormat definitions from schemas in the logformat directory
"""
import yaml
import json
import os
import re

LOGFORMAT_DIR = os.path.join(
    os.path.dirname(__file__),
    './logformat')
LOGFORMAT_NICKNAME_PREFIX = 'cee_ecs_accesslog'
LOGFORMAT_PREFIX = '@cee: '


def get_version(filename):
    """ extracts the version from the name of the file in Debian convention """
    return filename.split('_')[-1].replace('.yaml', '')


def get_apache_directive(file_content):
    """ Extracts the Apache directive from the yaml file content """
    for line in file_content.split('\n'):
        m = re.match(r'#\s+Apache-Directive:\s+(?P<directive>\w+)', line)
        if m:
            return m.group('directive')
    return 'LogFormat'


def generate_logformat(filename):
    """ returns a LogFormat line from file """
    nickname = LOGFORMAT_NICKNAME_PREFIX + '_' + get_version(filename).replace('.', '')

    with open(filename, 'r') as f:

        file_content = f.read()
        apache_directive = get_apache_directive(file_content)
        parsed = yaml.safe_load(file_content)

        json_config = json.dumps(
            parsed, sort_keys=True,
            # When a percent placeholder is not set, Apache "deletes everything
            # from the preceding space character to the next space character".
            # non-whitespace surrounding the token.
            #
            # Given the format:
            #
            #   {"client_ip": "%a", "ecs.version": "113"}
            #
            # When the client IP "%a" can't be determinated, the non-whitespace
            # characters are deleted resulting in invalid json:
            #
            #   {"client_ip": , "ecs.version": "113"}
            #               ^^^
            # Change the JSONEncoder key separator to not include a space:
            #
            #   {"client_ip":"%a", "ecs.version":"113"}
            #
            # Which lets Apache strips the whole field:
            #
            #   {"ecs.version": "113"}
            #
            separators=(", ", ":")
        )
        config_line = apache_directive + ' "' + LOGFORMAT_PREFIX \
            + json.dumps(json_config)[1:-1] \
            + '" '

    if apache_directive == 'LogFormat':
        config_line += ' ' + nickname

    return config_line


def main():
    for filename in os.listdir(LOGFORMAT_DIR):
        if filename[-4:] == 'yaml':
            print('# ' + filename)
            print(generate_logformat(
                filename=os.path.join(LOGFORMAT_DIR, filename),
            ))


if __name__ == '__main__':
    main()
