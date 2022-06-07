#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Utility to generate JSON LogFormat definitions from schemas in the logformat directory
"""
import yaml
import json
import os

LOGFORMAT_DIR = './logformat'
LOGFORMAT_NICKNAME_PREFIX = 'cee_ecs_accesslog'
LOGFORMAT_PREFIX = '@cee: '


def get_version(filename):
    """ extracts the version from the name of the file in Debian convention """
    return filename.split('_')[-1].replace('.yaml', '')


def generate_logformat(filename):
    """ returns a LogFormat line from file """
    nickname = LOGFORMAT_NICKNAME_PREFIX + '_' + get_version(filename).replace('.', '')
    with open(filename, 'r') as f:
        parsed = yaml.safe_load(f.read())
        return 'LogFormat "' + LOGFORMAT_PREFIX \
               + json.dumps(json.dumps(parsed, sort_keys=True))[1:-1] \
               + '" ' + nickname


def main():
    for filename in os.listdir(LOGFORMAT_DIR):
        if filename[-4:] == 'yaml':
            print('# ' + filename)
            print(
                generate_logformat(
                    os.path.join(LOGFORMAT_DIR, filename)
                )
            )


if __name__ == '__main__':
    main()
