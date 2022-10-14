#!/usr/bin/env python3
"""Small script to query puppetdb for changes that where performed in a specific time window"""
# SPDX-License-Identifier: Apache-2.0
from argparse import ArgumentParser
from datetime import datetime
from typing import Dict, Generator, Optional

import dateparser

from pypuppetdb import connect
from pypuppetdb.types import Report


def get_results(
    start_date: datetime, end_date: datetime, node_regex: Optional[str] = None
) -> Generator[Report, None, None]:
    """fetch and return results from puppetdb"""
    if node_regex:
        node_pql = f'and nodes {{ certname ~ "{node_regex}" }}'
    else:
        node_pql = ''
    db = connect()
    date_fmt = "%Y-%m-%d %H:%M:%S"
    pql = f"""
    reports {{
        start_time >= "{start_date.strftime(date_fmt)}" and
        start_time <= "{end_date.strftime(date_fmt)}"
        {node_pql}
        order by start_time
    }}
    """
    return db.pql(pql)


def get_args() -> None:
    """Parse arguments.

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('start_date', type=dateparser.parse)
    parser.add_argument(
        '-e', '--end-date', type=dateparser.parse, default=datetime.now()
    )
    parser.add_argument('--node-regex', help="A regex used to filter hosts")
    parser.add_argument('-v', '--verbose', action='count', default=0)
    return parser.parse_args()


def format_item(item: Dict, verbose: int) -> str:
    if verbose > 1:
        return (
            f"\t{item['type']}[{item['title']}]: ({item['property']})\n"
            f"\t--{item['old']}\n\t++{item['new']}"
        )
    return f"\t{item['type']}[{item['title']}]: ({item['property']})"


def main() -> int:
    """Main entry point.

    Returns:
        int: an int representing the exit code
    """
    args = get_args()
    results = get_results(args.start_date, args.end_date, args.node_regex)
    for result in results:
        try:
            events = result.events()
            first = next(events)
            print(f'{result.received.strftime("%H:%M:%S")}: {result.node} - {result.version}')
            if args.verbose == 0:
                continue
            print(format_item(first.item, args.verbose))
        except StopIteration:
            continue
        for event in events:
            print(format_item(event.item, args.verbose))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
