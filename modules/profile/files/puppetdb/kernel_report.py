#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Simple script to query puppetdb and make sure hosts are on a specific minimum kernel version"""
import logging
import re

from argparse import ArgumentParser
from collections import defaultdict
# this is deprecated we should switch to packaging.version.parse but that's third party
from distutils.version import LooseVersion

from pypuppetdb import connect


def get_args() -> None:
    """Parse arguments.

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('--buster', type=LooseVersion)
    parser.add_argument('--bullseye', type=LooseVersion)
    parser.add_argument('--bookworm', type=LooseVersion)
    parser.add_argument('--skip-dbs', action='store_true')
    parser.add_argument('--skip-wmcs', action='store_true')
    parser.add_argument('-v', '--verbose', action='count', default=0)
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


def get_puppetdb_kernel_version(target_major, db_connection):
    """return a hash of hostname to version"""
    # unfortunatly i cant work out how to get the facts with the initial query
    kernel_fact_matcher = re.compile(r'Debian\s+(?P<version>\d+\.\d+\.\d+)')
    nodes = {}
    pql = f"""
    inventory {{
        facts.kernelmajversion = "{target_major}"
    }}
    """
    results = db_connection.pql(pql)
    for result in results:
        match = kernel_fact_matcher.search(result.facts['kernel_details']['version'])
        if match is None:
            logging.warning(
                '%s: unable to parse kernel version (%s)',
                result.node, result.facts['kernel_details']['version']
            )
            continue
        nodes[result.node] = {
            'version': LooseVersion(match['version']),
            'codename': result.facts['os']['distro']['codename'],
        }
    return nodes


def get_service_owners(target_major, db_connection):
    """Query puppetdb and return a mapping of servers to their team owners."""
    pql = f"""
    resources {{
        type = "Class" and title = "Profile::Contacts"
        and nodes {{
            certname in inventory[certname] {{
                facts.kernelmajversion = "{target_major}"
            }}
        }}
    }}
    """
    results = db_connection.pql(pql)
    return {r.node: r.parameters['role_contacts'] for r in results}


def generate_report(target_versions, skip_dbs, skip_wmcs):
    """Generate a report based on the target_versions."""
    db_connection = connect()
    report = {
        'multiple_owners': {},
        'service_owner_hosts': defaultdict(list),
    }
    db_matcher = re.compile(r'^(?:db(?:store|proxy)?|es|pc)\d{4}\.')
    for _codename, min_kernel_version in target_versions.items():
        target_major = f"{min_kernel_version.version[0]}.{min_kernel_version.version[1]}"
        puppetdb_kernel_version = get_puppetdb_kernel_version(target_major, db_connection)
        service_owners = get_service_owners(target_major, db_connection)

        for node, owner in dict(sorted(service_owners.items(), key=lambda x: (x[1], x[0]))).items():
            # just pick the first owner for now
            try:
                if len(owner) > 1:
                    report['multiple_owners'][node] = ','.join(owner)
                owner = owner[0]
            except IndexError:
                # default to Unowned
                owner = "Unowned"
            if skip_wmcs and owner == 'WMCS':
                continue
            if skip_dbs and db_matcher.match(node):
                continue
            data = puppetdb_kernel_version[node]
            upgraded = 'x' if data['version'] >= min_kernel_version else ''
            report['service_owner_hosts'][owner].append(f"[{upgraded}] {node} ({data['codename']})")
    return report


def print_report(report):
    """Print report."""
    for team, hosts in report['service_owner_hosts'].items():
        print(f"{team} hosts\n{'='*40}")
        print("\n".join(hosts) + "\n\n")

    print(f"multiple owners hosts\n{'='*40}")
    for host, owners in report['multiple_owners'].items():
        print(f"{host}: {owners}")


def main():
    """Main method."""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    target_versions = {}
    if args.buster:
        target_versions['buster'] = args.buster
    if args.bullseye:
        target_versions['bullseye'] = args.bullseye
    if args.bookworm:
        target_versions['bookworm'] = args.bullseye
    report = generate_report(target_versions, args.skip_dbs, args.skip_wmcs)
    print_report(report)


if __name__ == '__main__':
    raise SystemExit(main())
