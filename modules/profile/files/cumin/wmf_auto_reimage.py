#!/usr/bin/env python
"""Automated reimaging of a list of hosts."""

import logging
import os
import socket
import subprocess
import sys
import time

from collections import defaultdict
from datetime import datetime

import wmf_auto_reimage_lib as lib


LOG_PATTERN = '/var/log/wmf-auto-reimage/{start}_{user}_{pid}.log'

logger = logging.getLogger('wmf-auto-reimage')


def parse_args():
    """Parse and return command line arguments, validate the hosts."""
    parser = lib.get_base_parser('Automated reimaging of a list of hosts')
    parser.add_argument(
        '--sequential', action='store_true',
        help=('run one reimage at a time, sequentially. By default the reimage for all the hosts '
              'are run in parallel.'))
    parser.add_argument(
        '--sleep', action='store', type=int, default=0,
        help=('amount of seconds to sleep between one reimage and the next when --sequential '
              'is set. Has no effect if --sequential is not set. [default: 0]'))
    parser.add_argument(
        '--force', action='store_true',
        help='override the default limit of that can be reimaged: 3 in parallel, 5 in sequence.')
    parser.add_argument(
        'hosts', metavar='HOST', nargs='+', action='store',
        help='FQDN of the host(s) to be reimaged')

    args = parser.parse_args()

    # Safety limits
    if not args.force:
        if args.sequential and len(args.hosts) > 5:
            parser.error('More than 5 sequential hosts specified and --force not set')
        elif len(args.hosts) > 3:
            parser.error(("More than 3 parallel hosts specified and --force not set. Before using "
                          "the --force parameter, ensure that there aren't too many hosts in the "
                          "same rack."))

    # Perform a quick sanity check on the hosts
    for host in args.hosts:
        if '.' not in host or not lib.HOSTS_PATTERN.match(host):
            parser.error("Expected FQDN of hosts, got '{host}'".format(host=host))

        if not lib.is_hostname_valid(host):
            parser.error("Unable to resolve host '{host}'".format(host=host))

    # Ensure there are no duplicates in the hosts list
    duplicates = {host for host in args.hosts if args.hosts.count(host) > 1}
    if len(duplicates) > 0:
        parser.error("Duplicate hosts detected: {dup}".format(dup=duplicates))

    # Ensure Phab task is properly formatted
    if (args.phab_task_id is not None and
            lib.PHAB_TASK_PATTERN.search(args.phab_task_id) is None):
        parser.error(("Invalid Phabricator task ID '{task}', expected in "
                      "the form T12345").format(task=args.phab_task_id))

    return args


def setup_logging(user):
    """Set up the logger instance and return the log file path.

    Arguments:
    user -- the real user to use in the logging formatter for auditing
    """
    log_path = LOG_PATTERN.format(
        start=datetime.utcnow().strftime('%Y%m%d%H%M'), user=user, pid=os.getpid())
    lib.setup_logging(logger, user, log_path)

    return log_path


def reimage_host(host, mgmt, args):
    """Run the reimage script for a single host in a subprocess.

    Arguments:
    host -- the FQDN of the host to be reimaged
    mgmt -- the FQDN of the management interface of the host
    args -- the parsed arguments to pass over to the reimage script
    """
    command = lib.get_reimage_host_command(host, mgmt, args)
    return subprocess.Popen(command)


def wait_for_childrens(procs):
    """Wait for all the childrens.

    Arguments:
    procs -- a dictionary with host: subprocess with the subprocesses to wait for
    """
    retcodes = defaultdict(list)
    while True:
        if not procs:
            break

        for host, proc in procs.items():
            ret = proc.poll()
            if ret is None:
                continue
            else:
                del procs[host]
                retcodes[ret].append(host)

        time.sleep(5)

    return retcodes


def run(args, user, log_path):
    """Run the reimage for all the hosts in subproceesses."""
    # Setup
    phab_client = lib.get_phabricator_client()
    lib.ensure_ipmi_password()
    mgmts = lib.get_mgmts(args.hosts)

    # Check that IPMI is working for all the hosts
    for host in args.hosts:
        lib.check_remote_ipmi(mgmts[host])

    # Initialize data structures
    procs = {}
    retcodes = defaultdict(list)

    # Validate hosts
    if not args.new:
        lib.validate_hosts(args.hosts, no_raise=args.no_verify)

    # Update the Phabricator task
    if args.phab_task_id is not None:
        lib.phabricator_task_update(
            phab_client, args.phab_task_id, lib.PHAB_COMMENT_PRE.format(
                user=user, hostname=socket.getfqdn(), hosts=args.hosts, log=log_path))

    # Run the reimage for each host in a child process
    try:
        for host in args.hosts:
            proc = reimage_host(host, mgmts[host], args)
            if args.sequential:
                retcodes[host] = proc.wait()
                time.sleep(args.sleep)
            else:
                procs[host] = proc

        if procs:
            retcodes = wait_for_childrens(procs)
    except KeyboardInterrupt:
        # Terminate childrens
        if procs:
            for process in procs:
                process.terminate()
        else:
            proc.terminate()

        raise

    # Comment on the Phabricator task
    if args.phab_task_id is not None:
        phabricator_message = lib.get_phabricator_post_message(retcodes)
        lib.phabricator_task_update(phab_client, args.phab_task_id, phabricator_message)

    if max(retcodes.keys()) > 0:
        return 1

    return 0


def main():
    """Automated reimaging of a list of hosts."""
    # Setup
    args = parse_args()
    lib.ensure_shell_mode()
    user = lib.get_running_user()
    log_path = setup_logging(user)
    if args.debug:
        logger.setLevel(logging.DEBUG)

    logger.info('wmf-auto-reimage called with args: {args}'.format(args=args))
    lib.print_line('START. To monitor the full log:')
    lib.print_line('sudo tail -F {log}'.format(log=log_path), skip_time=True)

    try:
        retcode = run(args, user, log_path)
    except BaseException as e:
        message = 'Unable to run wmf-auto-reimage'
        lib.print_line('{message}: {error}'.format(message=message, error=e))
        logger.exception(message)
        retcode = 2
    finally:
        lib.print_line('END')

    return retcode


if __name__ == '__main__':
    sys.exit(main())
