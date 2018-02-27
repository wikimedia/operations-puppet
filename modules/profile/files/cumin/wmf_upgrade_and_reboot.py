#!/usr/bin/env python

"""Upgrade software on a given host and reboot it

- Set Icinga downtime
- Depool
- Upgrade software
- Reboot
- Wait for host to come back online
- Wait for puppet run
- Remove Icinga downtime
- Repool

Usage example:
    wmf-upgrade-and-reboot lvs2002.codfw.wmnet --depool-cmd="systemctl stop pybal" \
        --repool-cmd="systemctl start pybal"
    wmf-upgrade-and-reboot cp3030.esams.wmnet --depool-cmd="depool" \
        --repool-cmd="pool"
"""

from __future__ import print_function

import argparse
import logging
import sys
import time

from datetime import datetime

import wmf_auto_reimage_lib as lib


NAME = 'wmf_upgrade_and_reboot'

logger = logging.getLogger()


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        'host', metavar='HOST', action='store', help='FQDN of the host to act upon')
    parser.add_argument(
        '--depool-cmd',
        required=True,
        help=('Command used to depool the service (eg: "service pybal stop")'))
    parser.add_argument(
        '--repool-cmd',
        required=True,
        help=('Command used to repool the service (eg: "pool")'))

    args = parser.parse_args()
    return args


def setup_logging(logger_instance, user):
    log_formatter = logging.Formatter(
        fmt=('%(asctime)s [%(levelname)s] ({user}) %(name)s::%(funcName)s: '
             '%(message)s').format(user=user),
        datefmt='%F %T')

    log_handler = logging.StreamHandler()
    log_handler.setFormatter(log_formatter)
    logger_instance.addHandler(log_handler)
    logger_instance.setLevel(logging.INFO)


def run_cumin(host, cmds, timeout=30, ignore_exit=False):
    try:
        lib.run_cumin(NAME, host, cmds, timeout=timeout, ignore_exit=ignore_exit)
    except RuntimeError:
        return False

    return True


def icinga_downtime(host, reason, seconds):
    icinga_host = lib.resolve_dns('icinga.wikimedia.org', 'CNAME')
    cmd = 'icinga-downtime -h {host} -d {seconds} -r "{reason}"'.format(
        host=host.split('.')[0], seconds=seconds, reason=reason)
    return run_cumin(icinga_host, [cmd], timeout=60)


def icinga_cancel_downtime(host):
    icinga_host = lib.resolve_dns('icinga.wikimedia.org', 'CNAME')
    cmd = 'echo "[{now}] DEL_DOWNTIME_BY_HOST_NAME;{hostname}"  > {commandfile}'.format(
        now=int(time.time()), hostname=host.split('.')[0],
        commandfile='/var/lib/nagios/rw/nagios.cmd')
    return run_cumin(icinga_host, [cmd], timeout=300)


def main():
    args = parse_args()
    user = lib.get_running_user()
    setup_logging(logger, user)

    if not lib.is_hostname_valid(args.host):
        logger.error("{} is not a valid hostname. Exiting.".format(args.host))
        return 1

    # Set Icinga downtime for the host to be upgraded
    icinga_downtime(args.host, "Software upgrade and reboot", 1200)

    # Depool and wait a bit for the host to be drained
    if args.depool_cmd is not None and not run_cumin(args.host, [args.depool_cmd]):
        logger.error("Failed depooling {}. Exiting.".format(args.host))
        return 1

    logging.info("Waiting for {} to be drained.".format(args.host))
    time.sleep(30)

    # Run apt full-upgrade
    if not run_cumin(args.host, ['apt -y full-upgrade'], timeout=300):
        logger.error("Failed upgrading {}. Exiting.".format(args.host))
        return 1

    reboot_time = datetime.utcnow()

    lib.reboot_host(args.host)

    boot_time = datetime.utcnow()

    lib.wait_reboot(args.host, start=reboot_time)

    lib.wait_puppet_run(args.host, start=boot_time)

    # Repool
    if args.repool_cmd is not None and not run_cumin(args.host, [args.repool_cmd]):
        logger.error("Failed repooling {}. Exiting.".format(args.host))
        return 1

    # Cancel Icinga downtime
    icinga_cancel_downtime(args.host)
    return 0


if __name__ == "__main__":
    sys.exit(main())
