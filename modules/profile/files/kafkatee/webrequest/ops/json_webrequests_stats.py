#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Script to parse sampled-1000.json or 5xx.json logs and report aggregated results.

The script expects as standard input a subset of lines from /srv/weblog/webrequest/*.json logs.
It uses the Python library `gjson` [1] that is the Python porting of the Go library GJSON [2] and
accepts the same syntax [3] for manipulating JSON objects.

Example usage:

    # Get stats from the live traffic
    tail -n 100000 /srv/weblog/webrequest/sampled-1000.json | json-webrequests-stats

    # Save the current live traffic to work on the same set of data while refining the search
    tail -n 100000 /srv/weblog/webrequest/sampled-1000.json > ~/sampled.json
    cat ~/sampled.json | json-webrequests-stats
    # There is some interesting traffic with a specific pattern, filter by it and get the
    # statistics relative to only that specific traffic
    cat ~/sampled.json | json-webrequests-stats -n 20 -c text -q 'uri_path="/w/api.php"'
    # Apply multiple filters to narrow down the search
    cat ~/sampled.json | json-webrequests-stats -n 20 -c text \\
        -q 'uri_path="/w/api.php"' 'user_agent%"SomeBot.*"'

    # Get stats from the live 5xx error logs
    tail -n 10000 /srv/weblog/webrequest/5xx.json | json-webrequests-stats

"""
import argparse
import json
import sys

import gjson


# Required to cope with possible encoding issues in the logs
sys.__stdin__.reconfigure(errors='surrogateescape')
sys.__stdout__.reconfigure(errors='surrogateescape')
# To report separate stats between the text and upload caches
CDNS = {'upload': '=', 'text': '!='}
# The metrics for which the top N most common values are reported, independently for each one
TOP_N = ('cache_status', 'http_status', 'hostname', 'ip', 'uri_host', 'uri_path', 'uri_query',
         'referer', 'user_agent')
# The metrics for which the top N of the sum of the SUM_N_SUM metrics are reported
SUM_N_GROUP = ('ip', 'uri_host', 'uri_path', 'referer', 'user_agent')
# The metrics to sum for the SUM_N_GROUP metrics
SUM_N_SUM = ('response_size', 'time_firstbyte')


class ArgparseFormatter(argparse.ArgumentDefaultsHelpFormatter,
                        argparse.RawDescriptionHelpFormatter):
    """Custom argparse formatter_class that mixins both features."""


def parse_args():
    epilog = '\n'.join([
        '[1]       Python gjson: https://volans-.github.io/gjson-py/index.html',
        '[2]           Go GJSON: https://github.com/tidwall/gjson/blob/master/README.md',
        '[3]       GJSON Syntax: https://github.com/tidwall/gjson/blob/master/SYNTAX.md',
        '[4] GJSON Query syntax: https://github.com/tidwall/gjson/blob/master/SYNTAX.md#queries',
    ])
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=ArgparseFormatter,
                                     epilog=epilog)
    parser.add_argument('-n', '--num', default=10,
                        help='How many top N items to return for each block.')
    parser.add_argument('-c', '--cdn', default='all', choices=['text', 'upload', 'all'],
                        help='For which CDN to show the stats.')
    parser.add_argument('-q', '--queries', nargs='*',
                        help=('A GJSON additional array query to use to pre-filter the data, '
                              'without the parentheses required by the GJSON syntax [4], e.g.: '
                              '-q \'uri_path="/w/api.php"\'. Accepts multiple values, e.g.: '
                              '-q \'uri_path="/w/api.php"\' \'uri_host="en.wikipedia.org"\'.'))
    return parser.parse_args()


def main():
    """Execute the program."""
    args = parse_args()
    data = []
    for line in sys.stdin:
        data.append(json.loads(line))

    # Gather first and last timestamps
    start = data[0]['dt']
    end = data[-1]['dt']

    # Initialize gjson with the data
    gjson_obj = gjson.GJSON(data)

    stats = {'upload': {}, 'text': {}}
    pre_queries = '.'.join([f'#({query})#' for query in args.queries]) if args.queries else ''

    if pre_queries:  # Check if the filter returns any result and store how many they are
        filtered_len = gjson_obj.get(f'{pre_queries}|#')
        if not filtered_len:
            print(f'No records found with filter `{pre_queries}`. Aborting.')
            return
        pre_queries += '.'

    for cdn, operator in CDNS.items():
        if args.cdn != 'all' and args.cdn != cdn:
            continue

        base_filter = f'{pre_queries}#(uri_host{operator}"upload.wikimedia.org")#'
        stats[cdn]['count'] = gjson_obj.get(f'{base_filter}|#')
        for key in TOP_N:
            stats[cdn][f'top N requests per {key}'] = gjson_obj.get(
                f'{base_filter}.{key}.@top_n:{{"n": {args.num}}}')

        for group in SUM_N_GROUP:
            for sum_key in SUM_N_SUM:
                stats[cdn][f'top N sum({sum_key}) per {group}'] = gjson_obj.get(
                    f'{base_filter}.@sum_n:{{"group":"{group}","sum":"{sum_key}","n":{args.num}}}')

    tot_records = len(data) if args.cdn == 'all' else stats[args.cdn]['count']
    msg_parts = [f'= Stats from {tot_records}']
    if pre_queries:
        msg_parts.append(f'(filtered to {filtered_len})')

    msg_parts.extend(['records between', start, 'and', end])
    if pre_queries:
        msg_parts.extend(['filter:', pre_queries])

    print_results(stats, ' '.join(msg_parts))


def print_results(stats, time_msg):
    print(time_msg)
    for cdn, cdn_stats in stats.items():
        if not cdn_stats:
            continue
        print('=' * len(time_msg))
        print(f'= Stats for {cdn} CDN from {cdn_stats["count"]} records\n')
        for key, values in cdn_stats.items():
            if not values or key == 'count':
                continue
            if 'time_firstbyte' in key:
                size = len(str(int(next(iter(values.values()))))) + 3
                fmt = '.2f'
                suffix = ' [seconds]'
            elif 'response_size' in key:
                size = len(str(int(next(iter(values.values())) / 1024 ** 2))) + 3
                fmt = '.2f'
                suffix = ' [MBs]'
            else:
                size = len(str(next(iter(values.values()))))
                fmt = ''
                suffix = ''

            print(f' -> {key}{suffix}')
            print('    ----------')
            for value, stat in values.items():
                if 'response_size' in key:
                    stat = stat / 1024 ** 2

                print(f'    {stat:{size}{fmt}} {value}')

            print()

        print()

    print(time_msg)


if __name__ == '__main__':
    main()
