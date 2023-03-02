#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
NRPE script to search puppetdb to find all hosts which perform a puppet change on
every puppet agent run
"""
import logging
import os
import re

from argparse import ArgumentParser, Namespace
from collections import defaultdict
from datetime import datetime, timedelta
from re import search
from typing import Dict, Optional, Set

from cumin import Config
from cumin.transports import clustershell
from pypuppetdb import connect
from pypuppetdb.api import API
from requests.packages.urllib3 import disable_warnings
from requests.packages.urllib3.exceptions import SubjectAltNameWarning
from spicerack import Spicerack


logger = logging.getLogger(__name__)  # pylint: disable=invalid-name
# TODO: remove this once the puppet CA issues certs with subjectAltName
disable_warnings(SubjectAltNameWarning)


def get_args() -> Namespace:
    """Parse arguments

    Returns:
        Namespace: the parse argparse namspace
    """

    def check_positive(value):
        value = int(value)
        if value <= 0:
            raise parser.error("%s is an invalid positive int value" % value)
        return value

    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-w', '--warning', default=1, type=check_positive)
    parser.add_argument('-c', '--critical', default=5, type=check_positive)
    parser.add_argument(
        '--max-age',
        default=12,
        type=check_positive,
        help='the maximum report age in hours',
    )
    parser.add_argument(
        '-D', '--dev', action='store_true', help='Also include dev servers in counts'
    )
    parser.add_argument('--ssl-key', help='Path to the puppet agent ssl key to use')
    parser.add_argument('--ssl-cert', help='Path to the puppet agent ssl cert to use')
    parser.add_argument(
        '--ssl-ca', help='Path to the ssl ca-bundle used to verify the ssl connection'
    )
    parser.add_argument('-v', '--verbose', action='count', default=0)
    args = parser.parse_args()
    if args.warning >= args.critical:
        parser.error('--warning must be lower then --critical')
    return args


def get_log_level(level: int) -> None:
    """Configure logging

    Arguments:
        level: The logging level

    """
    return {
        0: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(level, logging.DEBUG)


def get_inactive_alert_hosts(pdb: API) -> Set:
    """Return a list of inactive alerting hosts

    Arguments:
        pql: an pypuppetdb api object

    Returns:
        set: of inactive alert hosts

    """
    pql = r"""
    resources[parameters]  {
        type = 'Class' and title = 'Profile::Alertmanager' and
        nodes { certname ~ "alert\\d+\\.wikimedia\\.org" }
        limit 1
    }
    """
    result = list(pdb.pql(pql))[0]
    hosts = {
        host.split('.')[0] for host in
        result['parameters']['partners']
        + [result['parameters']['active_host']]
    }
    logger.debug("passive alert hosts: %s", ",".join(hosts))
    return hosts


def get_node_status(pdb: API, max_age: datetime) -> Dict:
    """Return a list of inactive alerting hosts

    Arguments:
        pql: an pypuppetdb api object
        max_age: filter reports no older this this date

    Returns:
        dict: a dict of hosts with keys representing counts for each status

    """
    pql = f"""
    reports[count(status), certname, status] {{
        receive_time > "{max_age.isoformat()}"
        group by status, certname
    }}
    """
    nodes = defaultdict(dict)
    reports = pdb.pql(pql)

    for report in reports:
        hostname = report['certname'].split('.')[0]
        nodes[hostname][report['status']] = report['count']

    return nodes


def filter_failed_nodes(nodes: Dict, skip_regex: Optional[re.Pattern] = None) -> Set:
    """Filter the nodes dict to produce a set of constantly changing hosts.

    Arguments:
        nodes: A dict of hosts with keys representing counts for each status
        skip_regex: A regex of hosts to skip

    """
    failed_nodes = set()
    for fqdn, node in nodes.items():
        # skip hosts with no unchanged reports:
        if node.get('unchanged', 0):
            continue
        if (
            skip_regex is not None
            and search(skip_regex, fqdn.split('.')[0]) is not None
        ):
            logger.debug('%s: Skipping staging host', fqdn)
            continue
        failed_nodes.add(fqdn)
    return failed_nodes


def filter_icinga_nodes(nodes: Set, skip_icinga: Set, verbose: bool) -> Set:
    """Check icinga and filter out any hosts that are downtimed or not active.

    Arguments:
        nodes: A set of hosts to filter
        skip_icinga: a set of hosts to exclude when checking icinga
        verbose_level: boolean value passed to spicerack verbose paramter

    """
    # TODO: Remove temporary workaround once Cumin has full support to suppress output (T212783)
    stdout = clustershell.sys.stdout
    stderr = clustershell.sys.stderr
    try:
        with open(os.devnull, 'w') as discard_output:
            clustershell.sys.stdout = discard_output
            clustershell.sys.stderr = discard_output
            icinga = Spicerack(verbose=verbose, dry_run=False).icinga_hosts(
                nodes - skip_icinga
            )
            icinga_status = icinga.get_status('puppet last run')
    finally:
        clustershell.sys.stdout = stdout
        clustershell.sys.stderr = stderr

    ignored_nodes = {
        node.name
        for node in icinga_status.values()
        if node.downtimed
        or not node.notifications_enabled
        or node.services[0].acked
    }
    return nodes - ignored_nodes


def icinga_exit(nodes: Set, critical: int, warning: int) -> int:
    """Check the nodes agans the critical and warning values and pick the correct exit status.

    Arguments:
        nodes: the set of nodes to check
        critical: Exit with critical if the nodes are greater then this value
        warning: Exit with warning if the nodes are greater then this value

    Return:
        int: the exit code to use
    """
    if len(nodes) < warning:
        print('OK: all nodes running as expected')
        return 0

    if len(nodes) >= critical:
        status = 'CRITICAL'
        exit_code = 2
    else:
        status = 'WARNING'
        exit_code = 1
    print(
        f"{status}: the following ({len(nodes)}) node(s) "
        f"change every puppet run: {', '.join(sorted(nodes))}"
    )
    return exit_code


def main() -> int:
    """main entry point

    Returns:
        int: the status code to exit with

    """
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))

    failed_nodes = set()
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

    max_age = datetime.utcnow() - timedelta(hours=args.max_age)

    nodes = get_node_status(pdb, max_age)
    # skip staging servers:
    # - hostname starting labstest*
    # - hostname ending dev or dev\d{4}
    # - hostname ending test or test\d{4}
    skip_regex = (
        re.compile(r'(:?^labtest|(:?dev|test)(:?\d{4})?$)') if args.dev else None
    )
    failed_nodes = filter_failed_nodes(nodes, skip_regex)

    if failed_nodes:
        inactive_alert_hosts = get_inactive_alert_hosts(pdb)
        failed_nodes = filter_icinga_nodes(failed_nodes, inactive_alert_hosts, args.verbose > 2)
    return icinga_exit(failed_nodes, args.critical, args.warning)


if __name__ == '__main__':
    try:
        EXIT_CODE = main()
    except Exception as error:  # pylint: disable=broad-except
        print('UNKNOWN: {}'.format(error))
        EXIT_CODE = 3
    raise SystemExit(EXIT_CODE)
