#!/usr/bin/env python3
"""Script to act on and query the admin modules data.yaml"""
import logging

from argparse import ArgumentParser, Namespace
from pathlib import Path
from typing import Dict, List

import yaml


def get_args() -> None:
    """Parse arguments.

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    default_path = Path(__file__).parent.resolve() / '../data/data.yaml'
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-d', '--data_yaml', default=default_path, type=Path)
    parser.add_argument('-v', '--verbose', action='count', default=0)

    subparsers = parser.add_subparsers(help='sub-command help', dest='action', required=True)

    nextgid = subparsers.add_parser('nextgid')
    nextgid.add_argument('--min', help='The minimum gid (inclusive)', default=700, type=int)
    nextgid.add_argument('--max', help='The maximum gid (inclusive)', default=899, type=int)

    nextgid = subparsers.add_parser('findusers')
    nextgid.add_argument('--min', help='The minimum gid (inclusive)', default=500, type=int)
    nextgid.add_argument('--max', help='The maximum gid (inclusive)', default=999, type=int)
    nextgid.add_argument('--system', help='Wether to include system users', action='store_true')

    return parser.parse_args()


def get_log_level(args_level: int) -> int:
    """Convert an integer to a logging log level.

    Arguments:
        args_level (int): The log level as an integer

    Returns:
        int: the logging loglevel
    """
    return {
        0: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


def get_next(numbers: List[int]) -> int:
    """loops through a sorted list and get the next first number missing
    from the sequence

    Arguments:
        numbers (list): a sorted list of numbers

    Return:
        int: the next number missing from the sequence of numbers

    >>> get_next([])
    1
    >>> get_next([1])
    2
    >>> get_next([1,2,3])
    4
    >>> get_next([1,2,4])
    3
    >>> get_next([701,702,704])
    703
    """
    if len(numbers) == 1:
        return numbers[0] + 1
    if len(numbers) == 0:
        return 1
    try:
        return next(i for i in range(numbers[0], numbers[-1]+1) if i not in numbers)
    except StopIteration:
        # all numbers in the list are sequential
        return numbers[-1] + 1


def get_nextgid(data: Dict, args: Namespace) -> int:
    """Return the next available gid.

    Arguments:
        data (dict): The parsed yaml data

    Returns:
        int the free nextgid
    """
    gids = sorted([g['gid'] for g in data['groups'].values()
                   if args.min <= g.get('gid', -1) <= args.max])
    return get_next(gids)


def findusers(data: Dict, args: Namespace) -> list:
    """return a list of user matching the query"""
    if args.system:
        return [k for k, v in data['users'].items() if args.min <= v['uid'] <= args.max]
    return [k for k, v in data['users'].items()
            if args.min <= v['uid'] <= args.max and not v.get('system', False)]


def main() -> int:
    """Main entry point.

    Returns:
        int: an int representing the exit code
    """
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    data = yaml.safe_load(args.data_yaml.read_text())
    results = {
        'nextgid': get_nextgid,
        'findusers': findusers,
    }.get(args.action)(data, args)
    print(results)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
