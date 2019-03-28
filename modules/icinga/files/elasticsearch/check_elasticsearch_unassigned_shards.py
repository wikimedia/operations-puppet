#!/usr/bin/python3

"""Elasticsearch check for unassigned shards.

This script checks for failed shard allocation.

Example:
    $ python3 check_elasticsearch_unassigned_shards.py --url http://local:9200
    $ python3 check_elasticsearch_unassigned_shards.py --warning 2 --critical 4
"""

import argparse
import sys

from datetime import datetime, timedelta, timezone

import requests

from dateutil.parser import parse


EX_OK = 0
EX_WARNING = 1
EX_CRITICAL = 2
EX_UNKNOWN = 3


def get_unassigned_shards(base_url, timeout):
    url = "{base_url}/_cat/shards".format(base_url=base_url)
    result = requests.get(url, headers={'Accept': 'application/json'}, timeout=timeout)
    shards = [ushard for ushard in result.json() if ushard['state'] == 'UNASSIGNED']
    return shards


def check_unassigned_shards(base_url, timeout, shards, warning, critical):
    warnings = []
    criticals = []
    for shard in shards:
        result = explain_unassigned_shard(base_url, timeout, shard)
        threshold = check_threshold(result, warning, critical)
        if threshold == EX_CRITICAL:
            criticals.append(result)
        elif threshold == EX_WARNING:
            warnings.append(result)

    return warnings, criticals


def explain_unassigned_shard(base_url, timeout, shard):
    url = "{base_url}/_cluster/allocation/explain".format(base_url=base_url)
    if shard['prirep'] == 'r':
        data = {"index": shard['index'], "shard": int(shard['shard']), "primary": False}
    else:
        data = {"index": shard['index'], "shard": int(shard['shard']), "primary": True}
    result = requests.get(url, json=data, timeout=timeout)
    result.raise_for_status()
    result = result.json()
    if 'unassigned_info' in result:
        return result
    else:
        return None


def check_threshold(explained_shard, warning, critical):
    if explained_shard is None:
        return EX_OK

    now = datetime.now(timezone.utc)
    unassigned_on = parse(explained_shard['unassigned_info']['at'])
    if now - unassigned_on >= critical:
        return EX_CRITICAL
    elif now - unassigned_on >= warning:
        return EX_WARNING
    else:
        return EX_OK


def trigger_alert(warnings, criticals):
    if criticals:
        criticals.extend(warnings)
        log_output('CRITICAL', prepare_msg(criticals))
        return EX_CRITICAL
    elif warnings:
        log_output('WARNING', prepare_msg(warnings))
        return EX_WARNING
    else:
        log_output('OK', 'All good!')
        return EX_OK


def log_output(status, msg):
    print("{status} - {msg}".format(status=status, msg=msg))


def prepare_msg(items):
    all_alert_items = []
    for item in items:
        all_alert_items.append("{index}[{shard}]({at})".format(
            index=item['index'],
            shard=item['shard'],
            at=item['unassigned_info']['at']
        ))

    return ", ".join(all_alert_items)


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--url', default='http://localhost:9200', metavar='URL',
                        help='Elasticsearch endpoint')
    parser.add_argument('--timeout', default=4, type=int, metavar='TIMEOUT',
                        help='Timeout for the request to complete')
    parser.add_argument('--warning', default=2, type=int, metavar='WARNING',
                        help='Warning threshold for number of days shard has stayed unassigned')
    parser.add_argument('--critical', default=3, type=int, metavar='CRITICAL',
                        help='Critical threshold for number of days shard has stayed unassigned')
    opt = parser.parse_args()

    try:
        result = get_unassigned_shards(opt.url, opt.timeout)
        if not result:
            log_output('OK', 'All good')
            return EX_OK
        warnings, criticals = check_unassigned_shards(
            opt.url,
            opt.timeout,
            result,
            timedelta(days=opt.warning),
            timedelta(days=opt.critical)
        )
        return trigger_alert(warnings, criticals)
    except Exception as e:
        log_output('UNKNOWN', e)
        return EX_UNKNOWN


if __name__ == '__main__':
    sys.exit(main())
