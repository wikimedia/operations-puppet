#!/usr/bin/python3
"""Simple policy-rc.d script to allow disabling daemons auto starting on install

The script implements the API documented in:
 https://people.debian.org/~hmh/invokerc.d-policyrc.d-specification.txt

It should be noted that we only implement a minimum set of the api.  All arguments will
be accepted whoever the following arguments have no affect

* --list
* --quite
* runlevel

Further the stop and force-stop actions also result in no action
"""
from argparse import ArgumentParser
from pathlib import Path


def get_args() -> None:
    """Parse arguments.

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(
        '--quiet',
        action='store_true',
        help='This argument has no action and is only here to conform to the API',
    )
    parser.add_argument(
        '--list',
        action='store_true',
        help='This argument has no action and is only here to conform to the API',
    )
    parser.add_argument('initscript')
    parser.add_argument('action')
    parser.add_argument(
        'runlevels',
        nargs='?',
        help='This argument has no action and is only here to conform to the API',
    )
    return parser.parse_args()


def main() -> int:
    """Main entry point.

    Returns:
        int: an int representing the exit code
    """
    base_dir = Path('/etc/wikimedia/policy-rc.d/')
    args = get_args()
    # deny all action except stop which is used for uninstalling
    if (base_dir / args.initscript).is_file() and args.action not in [
        'stop',
        'forcestop',
    ]:
        return 101
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
