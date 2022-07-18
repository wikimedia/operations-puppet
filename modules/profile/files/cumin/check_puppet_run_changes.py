#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
NRPE script to search puppetdb to find all hosts which perform a puppet change on
every puppet agent run
"""
import logging
import os

from argparse import ArgumentParser
from collections import defaultdict
from datetime import datetime, timedelta
from re import search

from cumin import Config
from cumin.transports import clustershell
from pypuppetdb import connect
from pypuppetdb.QueryBuilder import ExtractOperator, FunctionOperator, GreaterOperator
from requests.packages.urllib3 import disable_warnings
from requests.packages.urllib3.exceptions import SubjectAltNameWarning
from spicerack import Spicerack


logger = logging.getLogger(__name__)  # pylint: disable=invalid-name
# TODO: remove this once the puppet CA issues certs with subjectAltName
disable_warnings(SubjectAltNameWarning)


def get_args():
    """Parse arguments"""

    def check_positive(value):
        value = int(value)
        if value <= 0:
            raise parser.error("%s is an invalid positive int value" % value)
        return value

    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-w', '--warning', default=1, type=check_positive)
    parser.add_argument('-c', '--critical', default=5, type=check_positive)
    parser.add_argument(
        '--max-age', default=12, type=check_positive, help='the maximum report age in hours'
    )
    parser.add_argument(
        '-D', '--dev', action='store_true', help='Also include dev servers in counts'
    )
    parser.add_argument('--ssl-key', help='Path to the puppet agent ssl key to use')
    parser.add_argument('--ssl-cert', help='Path to the puppet agent ssl cert to use')
    parser.add_argument(
        '--ssl-ca', help='Path to the ssl ca-bundle used to verify the ssl connection'
    )
    parser.add_argument('-v', '--verbose', action='count')
    args = parser.parse_args()
    if args.warning >= args.critical:
        parser.error('--warning must be lower then --critical')
    return args


def get_log_level(args_level):
    """Configure logging"""
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


def main():
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))

    failed_nodes = []
    cumin_config = Config()
    pdb_config = {
        'host': cumin_config['puppetdb']['host'],
        'port': cumin_config['puppetdb']['port'],
    }
    if args.ssl_key and args.ssl_cert:
        pdb_config['ssl_key'] = args.ssl_key
        pdb_config['ssl_cert'] = args.ssl_cert
    elif args.ssl_key or args.ssl_cert:
        print('UNKNOWN: Must specify both ssl_key and ssl_cert')
        return 3
    if args.ssl_ca:
        pdb_config['ssl_verify'] = args.ssl_ca

    pdb = connect(**pdb_config)
    nodes = defaultdict(dict)

    max_age = datetime.utcnow() - timedelta(hours=args.max_age)

    extract = ExtractOperator()
    extract.add_field(['certname', FunctionOperator('count'), 'status'])
    extract.add_group_by(['certname', 'status'])
    extract.add_query(GreaterOperator('receive_time', max_age.isoformat()))

    # pypuppetdb does have a `reports` method which wraps `_query`.  however it yields
    # results of type pypuppetdb.Report which expects a number of parameters e.g. hash
    # to be present in the result payload.  however we don't extract theses values and
    # therefore have to resort to the more powerful private method
    reports = pdb._query('reports', query=extract)  # pylint: disable=protected-access

    for report in reports:
        nodes[report['certname']][report['status']] = report['count']

    if args.dev:
        failed_nodes = [
            fqdn for fqdn, node in nodes.items() if not node.get('unchanged', 0)
        ]
    else:
        for fqdn, node in nodes.items():
            # skip hosts with no unchanged reports:
            if node.get('unchanged', 0):
                continue
            # skip staging servers:
            # - hostname starting labstest*
            # - hostname ending dev or dev\d{4}
            # - hostname ending test or test\d{4}
            if (
                fqdn.startswith('labtest')
                or search(r'(:?dev|test)(:?\d{4})?$', fqdn.split('.')[0]) is not None
            ):
                logger.debug('%s: Skipping staging host', fqdn)
                continue
            failed_nodes.append(fqdn)

    if failed_nodes:
        # only run spicerack in verbose if using debug
        verbose = False if args.verbose is None else args.verbose > 2

        # TODO: Remove temporary workaround once Cumin has full support to suppress output (T212783)
        stdout = clustershell.sys.stdout
        stderr = clustershell.sys.stderr
        try:
            with open(os.devnull, 'w') as discard_output:
                clustershell.sys.stdout = discard_output
                clustershell.sys.stderr = discard_output
                icinga = Spicerack(verbose=verbose, dry_run=False).icinga_hosts(failed_nodes)
                icinga_status = icinga.get_status()
        finally:
            clustershell.sys.stdout = stdout
            clustershell.sys.stderr = stderr
        failed_nodes = [
            node.name
            for node in icinga_status.values()
            if node.notifications_enabled and not node.downtimed
        ]

    if len(failed_nodes) >= args.critical:
        print(
            'CRITICAL: the following ({}) node(s) change every puppet run: {}'.format(
                len(failed_nodes), ', '.join(sorted(failed_nodes))
            )
        )
        return 2
    if len(failed_nodes) >= args.warning:
        print(
            'WARNING: the following ({}) node(s) change every puppet run: {}'.format(
                len(failed_nodes), ', '.join(sorted(failed_nodes))
            )
        )
        return 1

    print('OK: all nodes running as expected')
    return 0


if __name__ == '__main__':
    try:
        EXIT_CODE = main()
    except Exception as error:  # pylint: disable=broad-except
        print('UNKNOWN: {}'.format(error))
        EXIT_CODE = 3
    raise SystemExit(EXIT_CODE)
