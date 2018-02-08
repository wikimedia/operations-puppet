#!/usr/bin/env python

"""Upgrade/downgrade Varnish on the given cache host between version 4 and
version 5

- Set Icinga downtime
- Depool
- Disable puppet
- Wait for admin to merge hiera puppet change
- Remove packages
- Re-enable puppet and run it to upgrade
- Run a test request through frontend and backend
- Remove Icinga downtime
- Repool
"""

from __future__ import print_function

import argparse
import logging
import sys
import time

import wmf_auto_reimage_lib as lib

import requests

NAME = 'wmf_upgrade_varnish'

logger = logging.getLogger()


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        'host', metavar='HOST', action='store', help='FQDN of the host to act upon')
    parser.add_argument(
        '--downgrade', action='store_true',
        help='Downgrade varnish instead of upgrading it')

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


def ask_confirmation(message):
    print(message)
    print('Type "done" to proceed')

    for _ in xrange(3):
        resp = raw_input('> ')
        if resp == 'done':
            break

        print('Invalid response, please type "done" to proceed.')
        print('After 3 wrong answers the task will be aborted.')
    else:
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


def pre_puppet(host, downgrading):
    experimental_repo = ('echo deb http://apt.wikimedia.org/wikimedia jessie-wikimedia experimental'
                         ' > /etc/apt/sources.list.d/wikimedia-experimental.list')

    if downgrading:
        experimental_repo = 'rm /etc/apt/sources.list.d/wikimedia-experimental.list'

    cmds = [
        experimental_repo,
        'apt update',
        'service varnish-frontend stop',
        'service varnish stop',
        'apt-get -y remove libvarnishapi1',
    ]

    return run_cumin(host, cmds, ignore_exit=True, timeout=7200)


def post_puppet(host):
    cmds = [
        'service varnish restart',
        'service varnish-frontend restart',
        'run-puppet-agent',
        'systemctl restart prometheus-varnish-exporter@frontend.service',
    ]
    return run_cumin(host, cmds, ignore_exit=True, timeout=7200)


def check_http_responses(host):
    req = requests.head('http://{}'.format(host))
    if req.status_code not in (200, 404):
        logger.error("Unexpected response from varnish-fe. "
                     "Got {} instead of 200/404. Exiting.".format(req.status_code))
        return False

    req = requests.head('http://{}:3128'.format(host))
    if req.status_code not in (200, 404):
        logger.error("Unexpected response from varnish-be. "
                     "Got {} instead of 200/404. Exiting.".format(req.status_code))
        return False

    return True


def main():
    args = parse_args()
    user = lib.get_running_user()
    setup_logging(logger, user)

    if not lib.is_hostname_valid(args.host):
        logger.error("{} is not a valid hostname. Exiting.".format(args.host))
        return 1

    action = 'Upgrading'
    if args.downgrade:
        action = 'Downgrading'

    reason = "{} Varnish on {} --{}".format(action, args.host, user)

    logger.info(reason)

    # Check that puppet is not already disabled
    if not run_cumin(args.host, ['puppet-enabled']):
        logger.error("puppet is disabled on {}. Exiting.".format(args.host))
        return 1

    # Set Icinga downtime for the host to be upgraded
    icinga_downtime(args.host, reason, 1200)

    # Depool and wait a bit for the host to be drained
    if not run_cumin(args.host, ['depool']):
        logger.error("Failed depooling {}. Exiting.".format(args.host))

    logging.info("Waiting for {} to be drained.".format(args.host))
    time.sleep(30)

    # Disable puppet
    if not run_cumin(args.host, ['disable-puppet "{message}"'.format(message=reason)]):
        logger.error("Failed to disable puppet on {}. Exiting.".format(args.host))
        return 1

    # Wait for admin to merge the puppet patch toggling hiera settings
    if not ask_confirmation("Waiting for you to puppet-merge "
                            "the change toggling {}'s hiera settings".format(args.host)):
        return 1

    # Remove old stuff
    pre_puppet(args.host, downgrading=args.downgrade)

    # Enable and run puppet
    cmd = 'run-puppet-agent --enable "{message}"'.format(message=reason)
    if not run_cumin(args.host, [cmd], timeout=7200):
        logger.error("Failed to enable and run puppet on {}. Exiting.".format(args.host))
        return 1

    # Post upgrade
    post_puppet(args.host)

    # check HTTP response from backend/frontend
    if args.host != "cp1008.wikimedia.org":
        # Skip HTTP check if working on pinkunicorn. PU is firewalled and does
        # not allow us to establish TCP connections to varnish.
        check_http_responses(args.host)

    # Repool
    if not run_cumin(args.host, ['pool']):
        logger.error("Failed repooling {}. Exiting.".format(args.host))

    # Cancel Icinga downtime
    icinga_cancel_downtime(args.host)
    return 0


if __name__ == "__main__":
    sys.exit(main())
