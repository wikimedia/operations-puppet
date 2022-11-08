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

    # Use a larger input and filter it by time range
    tail -n 100000 /srv/weblog/webrequest/sampled-1000.json | json-webrequests-stats \\
        -t 12:34-12:37:45

"""
import argparse
import json
import sys

from dataclasses import dataclass
from datetime import time
from typing import Any, Optional, Union

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


@dataclass(frozen=True)
class TimeRange:
    """Represent a time range."""
    start: Optional[time]  # From time
    end: Optional[time]  # To time
    source: str  # The original string from where the time range was parsed


def parse_time_range(string: str) -> TimeRange:
    """Parse and validate a -t/--time-range command line argument."""
    if not string:
        return TimeRange(start=None, end=None, source=string)

    parts = string.split('-')
    if len(parts) != 2:
        raise argparse.ArgumentTypeError(
            f'Invalid time range format {string}, expected one of `FROM-`, `-TO` or `FROM-TO`.')

    values = []
    for part in parts:
        value = None
        if part:
            try:
                value = time.fromisoformat(part)
            except ValueError as e:
                raise argparse.ArgumentTypeError(
                    f'Invalid time range format {part}. Expected format is HH:MM or HH:MM:SS '
                    f'(e.g. 12:34 or 12:34:56). {e}') from e

        values.append(value)

    if values[0] and values[1] and values[0] >= values[1]:
        raise argparse.ArgumentTypeError(
            f'Invalid time range {string}, TO must be greater than FROM.')

    return TimeRange(start=values[0], end=values[1], source=string)


def parse_args() -> argparse.Namespace:
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

    parser.add_argument('-t', '--time-range', default='', type=parse_time_range,
                        help=('Apply a time-range filter discarding all records outside of the '
                              'range. The range format must be [FROM]-[TO] where each time can be '
                              'in the format HH:MM or HH:MM:SS (e.g. 12:34 or 12:34:56). The date '
                              'is automatically taken from the first and last record '
                              'respectively. The interval is inclusive on both ends (i.e. FROM <= '
                              'timestamp <= TO). Either the FROM or the TO can be omitted. If the '
                              'FROM is omitted the argument must be specified with -t=/'
                              '--time-range= to avoid that `-` is interpreted as another option. '
                              'Valid time range values are: `-t \'FROM-\'` `-t=\'-TO\'` '
                              '`-t \'FROM-TO\'`. If a more fine-tuned selection is needed the '
                              '-q/--queries filter can be used with the `dt` field (i.e. -q '
                              '\'dt>="2022-01-01T12:34:56Z"\' \'dt<="2022-01-01T12:45:01Z"\').'))
    parser.add_argument('-q', '--queries', nargs='*',
                        help=('A GJSON additional array query to use to pre-filter the data, '
                              'without the parentheses required by the GJSON syntax [4], e.g.: '
                              '-q \'uri_path="/w/api.php"\'. Accepts multiple values, e.g.: '
                              '-q \'uri_path="/w/api.php"\' \'uri_host="en.wikipedia.org"\'.'))
    return parser.parse_args()


def load_data(args: argparse.Namespace) -> tuple[str, str, str, list[dict[str, Any]]]:
    """Load data from stdin, filtering it by start and end time, if set."""
    data = []
    date_start = ''
    skipped_before = 0
    start = ''

    buffer = []
    for line in sys.stdin:
        if args.time_range.start is None or start:
            line_data = json.loads(line)
            data.append(line_data)
            continue

        # A START time is set, bufferize
        buffer.append(line)
        if len(buffer) < 1000:
            continue

        line_data = json.loads(line)
        if line_data['dt'] == '-':
            continue  # Skip lines with dt="-" before a start time is found

        if not date_start:
            date_start = line_data['dt'][:10]

        if line_data['dt'] < f'{date_start}T{args.time_range.start}Z':
            skipped_before += len(buffer)
            buffer = []
            continue  # Skip lines before the given start time

        # Past the start, backtract to include missing lines
        for buffer_line in buffer:
            line_data = json.loads(buffer_line)
            if start:
                data.append(line_data)
                continue

            if line_data['dt'] == '-':
                continue  # Skip lines with dt="-" before a start time is found

            if line_data['dt'] < f'{date_start}T{args.time_range.start}Z':
                skipped_before += 1
                continue

            start = line_data['dt']
            data.append(line_data)

        buffer = []

    # Gather first timestamp, skipping dt="-" lines, if not already set above
    if not start:
        i = -1
        while True:
            i += 1
            if data[i]['dt'] != '-':
                start = data[i]['dt']
                break

    # Gather last timestamp, skippimg dt="-" lines and filter by time_to if is set
    i = 0
    date_end = ''
    skipped_after = 0
    while True:
        i -= 1
        if data[i]['dt'] == '-':
            continue  # Skip lines with dt="-" after a end time is found

        if args.time_range.end is None:  # Found a end, stop here
            break

        if not date_end:
            date_end = data[i]['dt'][:10]

        if data[i]['dt'] > f'{date_end}T{args.time_range.end}Z':
            skipped_after += 1
            continue  # Skip lines after the given end time

        break

    end = data[i]['dt']
    if date_end and i < -1:
        data = data[:i + 1]

    message = f'between {start} and {end}'
    if args.time_range.source:
        message += (f' (skipped {skipped_before} records from the start and {skipped_after} '
                    f'records from the end by -t/--time-range \'{args.time_range.source}\')')

    return start, end, message, data


def main() -> None:
    """Execute the program."""
    args = parse_args()
    start, end, time_message, data = load_data(args)

    # Initialize gjson with the data
    gjson_obj = gjson.GJSON(data)

    stats: dict[str, dict[str, dict[str, Union[int, float]]]] = {'upload': {}, 'text': {}}
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
            stats[cdn][f'top N requests per field `{key}`'] = gjson_obj.get(
                f'{base_filter}.{key}.@top_n:{{"n": {args.num}}}')

        for group in SUM_N_GROUP:
            for sum_key in SUM_N_SUM:
                stats[cdn][f'top N sum({sum_key}) per field `{group}`'] = gjson_obj.get(
                    f'{base_filter}.@sum_n:{{"group":"{group}","sum":"{sum_key}","n":{args.num}}}')

    msg_parts = [f'= Stats from {len(data)} records', time_message]
    if pre_queries:
        queries_msg = ' '.join(repr(query) for query in args.queries)
        msg_parts.append(f'filtered to {filtered_len} records by -q/--queries {queries_msg}')

    print_results(stats, ' '.join(msg_parts))


def print_results(stats: dict[str, dict[str, dict[str, Union[int, float]]]], time_msg: str) -> None:
    """Print the results."""
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
