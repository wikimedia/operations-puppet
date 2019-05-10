#!/usr/bin/python3
import argparse
import os
import re
import subprocess
import sys


def parse_drbd_overview():
    """
    Parse the output of running drbd-overview and construct a map of status
    data per resource, e.g.
    {
        resource1: {cstate: .., dstate: .., ..},
        resource2: {cstate: .., dstate: .., ..}
    }
    :returns: dict
    """

    # Define headers in drbd-overview
    headers = ['cstate', 'role', 'dstate', 'mount-point', 'fstype',
               'size', 'used', 'avail', 'use%']

    # Read contents of drbd-overview and split by new lines
    drbd_overview_raw = str(subprocess.check_output(
        ['/usr/sbin/drbd-overview']), 'utf-8').rstrip('\n').split('\n')

    # Split each line into a list - making a nested list, remove empty elements
    # and strip whitespaces in the rest
    drbd_overview_split = [[z.strip(' ') for z in
                            filter(lambda y: y != '', x.split(' '))]
                           for x in drbd_overview_raw]

    # Make a dict of status data per resource
    # Resource name is extracted from the first item of each list
    # e.g test is extracted from 1:test/0
    resource_status_map = {re.split(':|/', x[0])[1]:
                           dict(zip(headers, x[1:]))
                           for x in drbd_overview_split}

    return resource_status_map


def check_resource(resource, resource_status):
    """
    Compute resource status based on connection state, disk state and role,
    and construct and print an appropriate error string.
    :param resource: string
    :param role: string
    :param resource_status: dict
    :returns: boolean
    """
    cstate_ok = (resource_status['cstate'] == 'Connected')
    dstate_ok = (resource_status['dstate'] == 'UpToDate/UpToDate')

    drbd_ok = cstate_ok and dstate_ok

    if not drbd_ok:
        errors = []
        errors.append('{}: Unexpected connected state: {}'.format(
            resource, resource_status['cstate']) if not cstate_ok else '')
        errors.append('{}: Unexpected disk state: {}'.format(
            resource, resource_status['dstate']) if not dstate_ok else '')

        print(', '.join(filter(lambda e: e, errors)))

    return drbd_ok


def main():
    if not os.geteuid() == 0:
        print('Script not run as root')
        sys.exit(1)

    parser = argparse.ArgumentParser('Check DRBD Status')
    parser.add_argument('resource',
                        help='Name of resource or \'all\'')
    args = parser.parse_args()

    resource_status_map = parse_drbd_overview()

    if args.resource == 'all':
        if not all([check_resource(r, resource_status_map[r])
                    for r in resource_status_map.keys()]):
            sys.exit(1)
    elif not check_resource(
            args.resource, resource_status_map[args.resource]):
        sys.exit(1)

    print('DRBD Status OK')


if __name__ == '__main__':
    main()
