#!/usr/bin/env python
"""Automated reimaging of a list of hosts."""

import argparse
import logging
import os
import socket
import sys
import time

from datetime import datetime

import wmf_auto_reimage_lib as lib


LOG_PATTERN = '/var/log/wmf-auto-reimage/{start}_{user}_{pid}_{host}.log'

logger = logging.getLogger('wmf-auto-reimage')


def parse_args():
    """Parse and return command line arguments, validate the host."""
    parser = lib.get_base_parser('Automated reimaging of a single host')
    parser.add_argument(
        '--rename', help='FQDN of the new name to rename this host to while reimaging')
    parser.add_argument(
        '--rename-mgmt', help='FQDN of the new name management interface, see --rename')
    parser.add_argument(
        'host', metavar='HOST', action='store', help='FQDN of the host to be reimaged')
    parser.add_argument(
        'mgmt', metavar='MGMT', action='store', nargs='?', default=None,
        help='FQDN of the management interface for the host')

    args = parser.parse_args()

    fqdns = [args.host]

    if args.rename is not None:
        fqdns.append(args.rename)
        if args.no_pxe:
            raise argparse.ArgumentTypeError(
                'The --rename option cannot be used in conjunction with --no-pxe.')

    # Gather the management interfaces, if missing
    if args.mgmt is None:
        mgmts = lib.get_mgmts([args.host])
        args.mgmt = mgmts[args.host]
    else:
        mgmts = {args.host: args.mgmt}

    fqdns.append(args.mgmt)
    if args.rename is not None and args.rename_mgmt is None:
        mgmts.update(lib.get_mgmts([args.rename]))
        fqdns.append(mgmts[args.rename])

    # Perform a quick sanity check on the host and mgmt
    for name in fqdns:
        if '.' not in name or not lib.HOSTS_PATTERN.match(name):
            raise argparse.ArgumentTypeError("Expected FQDN, got '{name}'".format(name=name))

            if not lib.is_hostname_valid(name):
                raise argparse.ArgumentTypeError(
                    "Unable to resolve host '{name}'".format(name=name))

    for mgmt in mgmts.values():
        if '.mgmt.' not in mgmt:
            raise argparse.ArgumentTypeError(
                'The MGMT parameter {} does not follow the *.mgmt.* format'.format(mgmt)
            )

    return args


def setup_logging(user, host):
    """Set up the logger instance and return the log file path.

    Arguments:
    user -- the real user to use in the logging formatter for auditing
    """
    log_path = LOG_PATTERN.format(
        start=datetime.utcnow().strftime('%Y%m%d%H%M'), user=user, pid=os.getpid(),
        host=host.replace('.', '_'))
    lib.setup_logging(logger, user, log_path)

    return log_path


def run(args, user, log_path):
    """Run the WMF auto reimage according to command line arguments.

    Arguments:
    args     -- parsed command line arguments
    user     -- the user that launched the script, for auditing purposes
    log_path -- the path of the logfile
    """
    previous = None  # Previous state in conftool
    rename_from = None  # In case of host rename, hold the previous hostname

    # Validate hosts have a signed Puppet certificate
    if not args.new and not args.no_verify:
        lib.validate_hosts([args.host], args.no_verify)

    # Set Icinga downtime
    if not args.new and not args.no_downtime:
        lib.icinga_downtime(args.host, user, args.phab_task_id)

    # Depool via conftool
    if args.conftool and not args.new:
        previous = lib.conftool_depool(args.host, pooled=args.conftool_value)
        lib.print_line('Waiting 3 minutes to let the host drain', host=args.host)
        time.sleep(180)

    if args.no_pxe:
        lib.print_line('Skipping PXE reboot', host=args.host)
    else:
        lib.puppet_remove_host(args.host)  # Cleanup Puppet

        # Reboot into PXE mode to start the reimage
        lib.print_line(
            lib.ipmitool_command(args.mgmt, ['chassis', 'bootdev', 'pxe']).rstrip('\n'),
            host=args.host)
        status = lib.ipmitool_command(args.mgmt, ['chassis', 'power', 'status'])
        if status.startswith('Chassis Power is off'):
            lib.print_line('Current power status is off, powering on', host=args.host)
            ipmi_command = ['chassis', 'power', 'on']
        else:
            lib.print_line('Power cycling', host=args.host)
            ipmi_command = ['chassis', 'power', 'cycle']

        lib.print_line(lib.ipmitool_command(args.mgmt, ipmi_command).rstrip('\n'), host=args.host)

        # If the host is renamed, swap the hostnames now
        if args.rename is not None:
            rename_from = args.host
            args.host = args.rename
            args.mgmt = args.rename_mgmt

        # Ensure the host is booting into the installer using Cumin's direct backend
        lib.wait_reboot(args.host, start=datetime.utcnow(), installer=True)

    # Sign the new Puppet certificate
    if lib.puppet_wait_cert_and_sign(args.host):
        lib.puppet_first_run(args.host)
        # Ensure the host is in Icinga
        lib.run_puppet([lib.resolve_dns(lib.ICINGA_DOMAIN, 'CNAME')], no_raise=True)
        lib.icinga_downtime(args.host, user, args.phab_task_id)

    # Issue a reboot and wait for it and also for Puppet to complete
    if not args.no_reboot:
        reboot_time = datetime.utcnow()
        # Ensure the host is in the known hosts
        lib.run_puppet([socket.getfqdn()], no_raise=True)
        lib.reboot_host(args.host)
        boot_time = datetime.utcnow()
        lib.wait_reboot(args.host, start=reboot_time)
        lib.wait_puppet_run(args.host, start=boot_time)

    # Run Apache fast test
    if args.apache:
        lib.run_apache_fast_test(args.host)

    # The repool is *not* done automatically, the command to repool is printed and logged
    if args.conftool:
        lib.print_repool_message(previous, rename_from=rename_from, rename_to=args.rename)

    lib.print_line('Reimage completed', host=args.host)


def main():
    """Run the automated reimaging of a single host."""
    # Setup
    args = parse_args()
    lib.ensure_shell_mode()
    user = lib.get_running_user()
    log_path = setup_logging(user, args.host)
    cumin_output_path = log_path.replace('.log', '_cumin.out')
    if args.debug:
        logger.setLevel(logging.DEBUG)

    logger.info('wmf-auto-reimage-host called with args: {args}'.format(args=args))
    lib.print_line('REIMAGE START | To monitor the full log and cumin output:', host=args.host)
    lib.print_line('sudo tail -F {log}'.format(log=log_path), skip_time=True)
    lib.print_line('sudo tail -F {log}'.format(log=cumin_output_path), skip_time=True)

    try:
        lib.ensure_ipmi_password()
        lib.check_remote_ipmi(args.mgmt)
        if args.rename_mgmt:
            lib.check_remote_ipmi(args.rename_mgmt)

        if args.phab_task_id is not None:
            phab_client = lib.get_phabricator_client()
            lib.phabricator_task_update(
                phab_client, args.phab_task_id, lib.PHAB_COMMENT_PRE.format(
                    user=user, hostname=socket.getfqdn(), hosts=args.host, log=log_path))

        try:
            # This is needed due to a bug in tqdm and a limitation in Cumin
            with open(cumin_output_path, 'w', 1) as cumin_output:
                stderr = sys.stderr
                stdout = sys.stdout
                sys.stderr = cumin_output
                sys.stdout = cumin_output
                run(args, user, log_path)
                retcode = 0
        finally:
            sys.stderr = stderr
            sys.stdout = stdout
    except BaseException as e:
        message = 'Unable to run wmf-auto-reimage-host'
        lib.print_line('{message}: {error}'.format(message=message, error=e), host=args.host)
        logger.exception(message)
        retcode = 2
    finally:
        lib.print_line('REIMAGE END | retcode={ret}'.format(ret=retcode), host=args.host)

    # Comment on the Phabricator task
    if args.phab_task_id is not None:
        phabricator_message = lib.get_phabricator_post_message({retcode: [args.host]})
        lib.phabricator_task_update(phab_client, args.phab_task_id, phabricator_message)

    return retcode


if __name__ == '__main__':
    sys.exit(main())
