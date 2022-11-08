#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Wrapper script to call all logout.d scripts."""

import logging
import os
import sys

from argparse import ArgumentParser
from json import dumps
from pathlib import Path
from subprocess import run
from typing import Dict

from wmflib.idm import logoutd_args


# TODO: convert to dataclass when we drop support for python3.5
class ScriptOutput:
    """Simple dataclass to store script output"""

    def __init__(self, name: str, output: str, return_code: int) -> None:
        """Initialise class"""
        self.name = name
        self.output = output
        self.return_code = return_code

    def asdict(self) -> Dict:
        """Return this object represented as a dict"""
        return self.__dict__


def get_args() -> None:
    """Parse arguments.

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
        list: A list of unparsed arguments which will be passed directly to the wrapped scripts
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(
        '-D', '--script-dir', default='/etc/wikimedia/logout.d', type=Path
    )
    parser.add_argument('-v', '--verbose', action='count', default=0)
    parser.add_argument(
        '-S',
        '--script',
        action='append',
        help=(
            'Script to call, can be used multiple times. '
            'If not passed all scripts in script-dir will be called'
        ),
    )
    return parser.parse_known_args()


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


def main() -> int:
    """Main entry point.

    Returns:
        int: an int representing the exit code
    """
    args, scriptargs = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    try:
        logoutd_args(scriptargs)
    except SystemExit as error:
        print('The message above relates to the arguments sent to the wrapped scripts')
        raise error

    # logout scripts are not supported on Stretch (which has 3.5)
    if sys.version_info.minor < 7:
        return 0

    results = []
    for script in args.script_dir.iterdir():
        if not os.access(script, os.X_OK):
            logging.warning('%s: is not executable')
            continue
        if args.script and script not in args.script:
            logging.debug("%s: won't be called", script)
            continue
        arguments = [script] + scriptargs
        result = run(arguments, capture_output=True, check=False)
        script_output = ScriptOutput(
            script.name, result.stdout.decode(), result.returncode
        )
        # Use asdict so we don't have to worry about json serialisation
        results.append(script_output.asdict())
    print(dumps(results))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
