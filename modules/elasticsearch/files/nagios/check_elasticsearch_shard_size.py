#!/usr/bin/python3

"""Elasticsearch shard size check.

Simple script to alert when shards in an elasticsearch cluster grows
beyond the warning and critical threshold. This script helps us avoid
unnecessary shard growth as it might affect shard movement in the cluster.

Example:
    $ python3 check_elasticsearch_shard_size.py
    $ python3 check_elasticsearch_shard_size.py --url http://host:9200 --shard-size-warning 25

"""

import argparse
import sys

from collections import defaultdict
from statistics import mean

import requests


EX_OK = 0
EX_WARNING = 1
EX_CRITICAL = 2
EX_UNKNOWN = 3


def get_shards(base_url, timeout, unit):
    url = "{base_url}/_cat/shards?format=json&bytes={unit}".format(base_url=base_url, unit=unit)
    resp = requests.get(url, timeout=timeout)
    return resp.json()


def extract_large_shards(indices, shard_size_warning, shard_size_critical):
    warnings = defaultdict(list)
    criticals = defaultdict(list)
    for name, shard_sizes in indices.items():
        mean_size = mean(shard_sizes)
        if mean_size > shard_size_critical:
            criticals[name].append(mean_size)
        elif mean_size > shard_size_warning:
            warnings[name].append(mean_size)

    return warnings, criticals


def trigger_alert(warnings, criticals, unit='gb'):
    if criticals:
        criticals.update(warnings)
        log_output('CRITICAL', prepare_msg(criticals, unit))
        return EX_CRITICAL
    elif warnings:
        log_output('WARNING', prepare_msg(warnings, unit))
        return EX_WARNING
    else:
        log_output('OK', 'All good!')
        return EX_OK


def prepare_msg(shards, unit):
    all_alert_items = []
    for index, shard_size in sort_shards(shards):
        all_alert_items.append("{index}({shard_size}{unit})".
                               format(index=index, shard_size=shard_size, unit=unit))
    return ", ".join(all_alert_items)


def sort_shards(shards):
    indices = {}
    for index, shard_sizes in shards.items():
        indices[index] = max(shard_sizes)

    return sorted(indices.items(), key=lambda k_v: k_v[1], reverse=True)


def log_output(status, msg):
    print("{status} - {msg}".format(status=status, msg=msg))


def group_by_index(shards):
    indices = defaultdict(list)
    for shard in shards:
        if shard['prirep'] == 'p':
            indices[shard['index']].append(int(shard['store']))
    return indices


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--url', default='http://localhost:9200',
                        help='Elasticsearch endpoint')
    parser.add_argument('--timeout', default=4, type=int, metavar='SECONDS',
                        help='Timeout for the request to complete'),
    parser.add_argument('--bytes', default='gb', metavar='BYTES',
                        help='Unit of shard size. E.g:%(choices)',
                        choices=['b', 'kb', 'mb', 'gb'])
    parser.add_argument('--shard-size-warning', default=50, type=int,
                        dest='shard_size_warning', metavar='WARNING',
                        help='Notify when shard size go past the warning threshold.')
    parser.add_argument('--shard-size-critical', default=60, type=int,
                        dest='shard_size_critical', metavar='CRITICAL',
                        help='Notify when shard size goes beyond the critical threshold')
    options = parser.parse_args()

    try:
        shards = get_shards(options.url, options.timeout, options.bytes)
        indices = group_by_index(shards)
        warnings, criticals = extract_large_shards(
            indices,
            options.shard_size_warning,
            options.shard_size_critical
        )
        return trigger_alert(warnings, criticals, options.bytes)
    except Exception as e:
        log_output('UNKNOWN', e)
        return EX_UNKNOWN


if __name__ == '__main__':
    sys.exit(main())
