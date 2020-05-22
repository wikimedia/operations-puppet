#!/usr/bin/env python3
"""
NRPE script to search puppetdb to find all hosts which perform a puppet change on
every puppet agent run
"""
import logging

from argparse import ArgumentParser
from collections import defaultdict
from datetime import datetime, timedelta
from re import search

from pypuppetdb import connect
from pypuppetdb.QueryBuilder import ExtractOperator, FunctionOperator, GreaterOperator


logger = logging.getLogger(__name__)  # pylint: disable=invalid-name


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-w', '--warning', default=1, type=int)
    parser.add_argument('-c', '--critical', default=5, type=int)
    parser.add_argument('--max-age', default=12, type=int,
                        help='the maximum report age in hours')
    parser.add_argument('-D', '--dev', action='store_true',
                        help='Also include dev servers in counts')
    parser.add_argument('-v', '--verbose', action='count')
    return parser.parse_args()


def get_log_level(args_level):
    """Configure logging"""
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG}.get(args_level, logging.DEBUG)


def main():
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))

    failed_nodes = []
    pdb = connect()
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
        failed_nodes = [hostname for hostname, node in nodes.items()
                        if not node.get('unchanged', 0)]
    else:
        for fqdn, node in nodes.items():
            # skip hosts with no unchanged reports:
            if node.get('unchanged', 0):
                continue
            # skip staging servers:
            # - hostname starting labstest*
            # - hostname ending dev or dev\d{4}
            # - hostname ending test or test\d{4}
            if (fqdn.startswith('labtest')
                    or search(r'(:?dev|test)(:?\d{4})?$', fqdn.split('.')[0]) is not None):
                logger.debug('%s: Skipping staging host', fqdn)
                continue
            failed_nodes.append(fqdn)

    if len(failed_nodes) >= args.critical:
        print('CRITICAL: the following ({}) node(s) change every puppet run: {}'.format(
            len(failed_nodes), ', '.join(failed_nodes)))
        return 2
    if len(failed_nodes) >= args.warning:
        print('WARNING: the following ({}) node(s) change every puppet run: {}'.format(
            len(failed_nodes), ', '.join(failed_nodes)))
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
