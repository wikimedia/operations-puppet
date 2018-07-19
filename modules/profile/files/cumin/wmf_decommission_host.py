#!/usr/bin/env python3

"""Decommission a host from all inventories

- Revoke it's Puppet certificate
- Remove it from PuppetDB
- Downtime the host and its mgmt interface on Icinga.
  It will be removed at the next Puppet run on the Icinga host
- Remove it from DebMonitor
- Update the related Phabricator task
"""

import argparse
import logging
import os
import sys

import wmf_auto_reimage_lib as lib


logging.basicConfig()
logger = logging.getLogger()


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        'host', metavar='HOST', help='FQDN of the host to act upon')
    parser.add_argument(
        '-p', '--phab-task-id', required=True, help='the Phabricator task ID, i.e.: T12345')
    parser.add_argument(
        '--force', action='store_true', help='Proceed also if the hostname is not valid')

    args = parser.parse_args()
    return args


def main():
    """Run the script."""
    script_name = os.path.basename(__file__)
    args = parse_args()
    user = lib.get_running_user()
    phab_client = lib.get_phabricator_client()
    is_valid_host = lib.is_hostname_valid(args.host)
    actions = []

    if not is_valid_host and not args.force:
        logger.error("{host} is not a valid hostname. Aborting.".format(host=args.host))
        return 1

    # Remove from Puppet and PuppetDB
    lib.puppet_remove_host(args.host)
    actions += ['Revoked Puppet certificate', 'Removed from PuppetDB']

    # Downtime on Icinga both the host and the mgmt host, they will be removed by Puppet
    if is_valid_host:
        lib.icinga_downtime(args.host, user, args.phab_task, title=script_name)
        actions.append('Downtimed host on Icinga')
        mgmts = lib.get_mgmts([args.host])
        lib.icinga_downtime(mgmts[args.host], user, args.phab_task, title=script_name)
        actions.append('Downtimed mgmt interface on Icinga')

    # Remove from DebMonitor
    lib.debmonitor_remove_host(args.host)
    actions.append('Removed from DebMonitor')

    message = ('{script} was executed by {user} for {host} and performed the following actions:\n'
               '- {actions}').format(
        script=script_name, user=user, host=args.host, actions='\n- '.join(actions))
    lib.phabricator_task_update(phab_client, args.phab_task, message)

    return 0


if __name__ == "__main__":
    sys.exit(main())
