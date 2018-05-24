#!/usr/bin/env python
"""Downtime a host on Icinga."""

import argparse
import logging
import sys
import time

import wmf_auto_reimage_lib as lib


logging.basicConfig()
logger = logging.getLogger('wmf-downtime-host')


def parse_args():
    """Parse and return command line arguments, validate the host."""
    parser = argparse.ArgumentParser(
        description='Downtime a host on Icinga, after running Puppet on the Icinga host.')
    parser.add_argument(
        '-d', '--debug', action='store_true', help='debug level logging')
    parser.add_argument(
        '-s', '--sleep', type=int, help='amount of seconds to sleep before downtiming the host')
    parser.add_argument(
        '-p', '--phab-task-id', action='store', help='the Phabricator task ID, i.e.: T12345)')
    parser.add_argument(
        'host', metavar='HOST', action='store', help='FQDN of the host to be downtimed')

    args = parser.parse_args()

    # Perform a quick sanity check on the host and mgmt
    if '.' not in args.host or not lib.HOSTS_PATTERN.match(args.host):
        raise argparse.ArgumentTypeError("Expected FQDN, got '{host}'".format(host=args.host))

        if not lib.is_hostname_valid(args.host):
            raise argparse.ArgumentTypeError(
                "Unable to resolve host '{host}'".format(host=args.host))

    return args


def main():
    """Downtime a single host on Icinga."""
    args = parse_args()
    lib.ensure_shell_mode()
    user = lib.get_running_user()
    if args.debug:
        logger.setLevel(logging.DEBUG)

    if args.sleep:
        lib.print_line('Sleeping for {s} seconds'.format(s=args.sleep), host=args.host)
        time.sleep(args.sleep)

    try:
        lib.run_puppet([lib.resolve_dns(lib.ICINGA_DOMAIN, 'CNAME')], no_raise=True)
        lib.icinga_downtime(args.host, user, args.phab_task_id, title='wmf-downtime-host')
        retcode = 0
    except BaseException as e:
        message = 'Unable to run wmf-downtime-host'
        lib.print_line('{message}: {error}'.format(message=message, error=e), host=args.host)
        logger.exception(message)
        retcode = 2

    return retcode


if __name__ == '__main__':
    sys.exit(main())
