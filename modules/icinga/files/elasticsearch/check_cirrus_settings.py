#!/usr/bin/python3

"""Cirrus cluster settings check"""

import argparse
import requests
import sys

import yaml

from jsonpath_rw import parse


EX_OK = 0
EX_WARNING = 1
EX_CRITICAL = 2
EX_UNKNOWN = 3


def get_api_settings(base_url, timeout):
    url = "{base_url}/_cluster/settings".format(base_url=base_url)
    response = requests.get(url, timeout=timeout)
    return response.json()


def get_file_settings(setting_file):
    with open(setting_file) as raw_settings:
        settings = yaml.safe_load(raw_settings)
    if not settings:
        return []
    return settings


def compare_settings(expected, actual):
    not_aligned = []
    for setting in expected:
        for key, value in setting.items():
            query_result = find_setting(key, actual)
            if not query_result:
                not_aligned.append("{key} not found".format(key=key))
            else:
                matched = [match.value for match in query_result][0]
                if not is_setting_value_matched(value, matched):
                    not_aligned.append("{matched} does not match {value} for {key}".format(
                        matched=matched, value=value, key=key))

    return not_aligned


def find_setting(setting, settings):
    query_result = parse(setting).find(settings['transient'])
    if query_result:
        return query_result
    query_result = parse(setting).find(settings['persistent'])
    if query_result:
        return query_result

    return []


def is_setting_value_matched(expected, actual):
    if type(expected) in (dict, list):
        return expected.sort() == actual.sort()
    else:
        return expected == actual


def alert(items):
    if items:
        log_output('CRITICAL', ','.join(items))
        return EX_CRITICAL

    log_output('OK', 'All good!')
    return EX_OK


def log_output(status, msg):
    print("{status} - {msg}".format(status=status, msg=msg))


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--url', required=True, help='Elasticsearch endpoint')
    parser.add_argument('--timeout', default=4, type=int,
                        help='Timeout for the request to complete'),
    parser.add_argument('--settings-file', required=True,
                        help='settings file path '
                             'e.g "/etc/elasticsearch/cirrus_check_settings.yaml"')

    options = parser.parse_args()

    try:
        api_settings = get_api_settings(options.url, options.timeout)
        file_settings = get_file_settings(options.settings_file)
        not_aligned = compare_settings(file_settings, api_settings)
        return alert(not_aligned)
    except Exception as e:
        log_output('UNKNOWN', e)
        return EX_UNKNOWN


if __name__ == '__main__':
    sys.exit(main())
