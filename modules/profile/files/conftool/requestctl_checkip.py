#!/usr/bin/python3
"""
Tool to search requestctl ipblock data and determine of any blocks contain a specific ip address
"""

import logging

from argparse import ArgumentParser
from ipaddress import ip_address, ip_network
from pathlib import Path

import yaml


def get_args() -> None:
    """Parse arguments.

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(
        "-D", "--requestctl-dir", type=Path, default=Path("/srv/private/requestctl")
    )
    parser.add_argument("-v", "--verbose", action="count", default=0)
    parser.add_argument("ip")
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


def main() -> int:
    """Main entry point.

    Returns:
        int: an int representing the exit code
    """
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    exit_code = 1
    for ipblock in (args.requestctl_dir / "request-ipblocks").glob("**/*.yaml"):
        logging.debug("checking: {ipblock}")
        for network in yaml.load(ipblock.read_text())["cidrs"]:
            if ip_address(args.ip) in ip_network(network):
                print(f"{args.ip} in {ipblock}")
                exit_code = 0

    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
