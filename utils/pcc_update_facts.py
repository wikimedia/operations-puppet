#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""example script"""

import logging
import shlex

from argparse import ArgumentParser
from pathlib import Path
from subprocess import run

import yaml


def get_args() -> None:
    """Parse arguments.

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-v', '--verbose', action='count', default=0)
    parser.add_argument(
        '-w',
        '--wait',
        action='store_true',
        help='Wait for pcc_facts_processor to complete on the pcc-db host',
    )
    parser.add_argument(
        '--pcc-db', default='pcc-db1001.puppet-diffs.eqiad1.wikimedia.cloud'
    )
    parser.add_argument(
        '-m',
        '--puppet-master',
        help='The puppetmaster to pull from. Use production by default',
    )
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


def main() -> int:
    """Main entry point.

    Returns:
        int: an int representing the exit code
    """
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    if args.verbose > 0:
        verbose_args = ' -' + 'v' * args.verbose
    else:
        verbose_args = ''

    puppet_root_dir = Path(__file__).resolve().parent.parent
    puppet_master = args.puppet_master
    pcc_db = args.pcc_db
    pcc_db_file = (
        puppet_root_dir
        / f"hieradata/cloud/eqiad1/puppet-diffs/hosts/{pcc_db.split('.')[0]}.yaml"
    )

    if not pcc_db_file.is_file():
        logging.error("can't find config file for %s", pcc_db_file)
        return 1
    pcc_db_yaml = yaml.safe_load(pcc_db_file.read_text())
    allowed_masters = [
        puppetmaster
        for realm in pcc_db_yaml['puppet_compiler::uploader::realms'].values()
        for puppetmaster in realm
    ]
    common_file = puppet_root_dir / 'hieradata/common.yaml'
    if puppet_master is None:
        common_yaml = yaml.safe_load(common_file.read_text())
        puppet_master = common_yaml['puppet_ca_server']
    if puppet_master.split('.')[0] not in allowed_masters:
        print(f'{puppet_master} is not authorised to upload facts please see:')
        print(
            'https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Manually_update_cloud'
        )
    print(f'Generate facts on: {puppet_master}')
    facts_upload_cmd = (
        f'ssh {puppet_master} sudo /usr/local/sbin/puppet-facts-upload {verbose_args}'
    )
    if puppet_master.endswith('wmnet'):
        facts_upload_cmd += f" -p http://webproxy.{'.'.join(puppet_master.split('.')[1:])}:8080"

    logging.debug('running cmd: %s', facts_upload_cmd)
    run(shlex.split(facts_upload_cmd), check=True)
    if args.wait:
        process_facts_cmd = (
            f'ssh {pcc_db}  sudo -u jenkins-deploy '
            f'/usr/local/sbin/pcc_facts_processor {verbose_args}'
        )
    else:
        process_facts_cmd = (
            f'ssh {pcc_db} sudo systemctl start pcc_facts_processor.service'
        )
    print(f'process facts on: {pcc_db}')
    logging.debug('running cmd: %s', process_facts_cmd)
    run(shlex.split(process_facts_cmd), check=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
