#!/usr/bin/python3
"""Script used to genrate prometheus statistics.  By default this program
will use `puppet config print` to find files.  This means that if you run
as root the script will use the files generated via production puppet runs.
However id you run as your own user it will look for files in the user
specific dir.  e.g. /home/jbond/.puppet/cache/state.

You can also explicitly override the state directory and specify any directory.
The script will expect to find a agent_disabled.lock and last_run_report.yaml
file in this directory
"""
# Copyright 2017 Filippo Giunchedi
#                Wikimedia Foundation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import logging
import shlex
import sys

from pathlib import Path
from subprocess import run, PIPE
from typing import Optional

import yaml

from prometheus_client import CollectorRegistry, Gauge, Info, write_to_textfile
from prometheus_client.exposition import generate_latest

log = logging.getLogger(__name__)


class ArgparseFormatter(
    argparse.ArgumentDefaultsHelpFormatter, argparse.RawDescriptionHelpFormatter
):
    """Custom argparse formatter class"""


def _summary_stats(registry: CollectorRegistry, puppet_state_dir: Optional[Path] = None) -> None:
    summary_parse_fail = Gauge('summary_parse_fail', 'Failed to parse summary',
                               namespace='puppet_agent', registry=registry)
    summary_parse_fail.set(0)
    last_run = Gauge('last_run', 'Timestamp of last run',
                     namespace='puppet_agent', registry=registry)
    last_run.set(0)
    failed = Gauge('failed', 'Last run is considered a failure',
                   namespace='puppet_agent', registry=registry)
    failed.set(0)
    failed_events = Gauge('failed_events', 'Number of failures on last run',
                          namespace='puppet_agent', registry=registry)
    failed_events.set(0)
    resources_failed = Gauge('resources_failed', 'Number of failed resources on last run',
                             namespace='puppet_agent', registry=registry)
    resources_failed.set(0)
    resources_changed = Gauge('resources_changed', 'Number of resources changed on last run',
                              namespace='puppet_agent', registry=registry)
    resources_changed.set(-1)
    resources_total = Gauge('resources_total', 'Number of total resources on last run',
                            namespace='puppet_agent', registry=registry)
    resources_total.set(0)
    collection_error = Gauge('collection_error', 'Error collecting data',
                             namespace='puppet_agent', registry=registry)
    collection_error.set(0)
    catalog_version = Info('catalog_version', 'The current commit running on the host',
                           namespace='puppet_agent', registry=registry)

    if puppet_state_dir is None:
        summary_file = Path(puppet_config('lastrunfile'))
    else:
        summary_file = puppet_state_dir / 'last_run_summary.yaml'

    try:
        log.debug("Parsing %s", summary_file)
        summary_yaml = yaml.safe_load(summary_file.read_text())
    except yaml.YAMLError:
        log.error('Failed to parse yaml', exc_info=True)
        summary_parse_fail.set(1)
        return
    except IOError:
        log.error('Failed to read run summary', exc_info=True)
        collection_error.set(1)
        return

    if not summary_yaml:
        log.error('Summary yaml is falsy')
        failed.set(1)
        return

    log.debug('Parsed YAML: %s', summary_yaml)

    if 'time' in summary_yaml:
        last_run.set(summary_yaml['time'].get('last_run', 0))
    if 'resources' in summary_yaml:
        resources_failed.set(summary_yaml['resources'].get('failed', 1))
        resources_total.set(summary_yaml['resources'].get('total', -1))
    if 'changes' in summary_yaml:
        resources_changed.set(summary_yaml['changes'].get('total', -1))
    if 'events' in summary_yaml:
        failures = summary_yaml['events'].get('failure', 1)
        if failures > 0:
            failed_events.set(failures)
            failed.set(1)
    # Consider puppet failed even when we can't find the failure count
    else:
        failed.set(1)

    if ('version' in summary_yaml and 'config' in summary_yaml['version']
            and summary_yaml['version']['config']):
        # version is "(sha hash) $author - $subject"
        git_sha = summary_yaml['version']['config'].split()[0].strip('()')
        catalog_version.info({'git_sha': git_sha})


def collect_puppet_stats(
    registry: CollectorRegistry, puppet_state_dir: Optional[Path] = None
) -> None:
    """parse the last run summary file to gather facts"""
    puppet_enabled = Gauge('enabled', 'Puppet is currently enabled',
                           namespace='puppet_agent', registry=registry)
    puppet_enabled.set(1)

    if puppet_state_dir is None:
        lock_file = Path(puppet_config('agent_disabled_lockfile'))
    else:
        lock_file = puppet_state_dir / 'agent_disabled.lock'
    if lock_file.exists():
        log.debug("Found %s, puppet disabled", lock_file)
        puppet_enabled.set(0)

    _summary_stats(registry, puppet_state_dir)


def puppet_config(item: str) -> str:
    """return a puppet config value"""
    command = shlex.split("/usr/bin/puppet config print {}".format(item))
    result = run(command, stdout=PIPE, check=True)
    return result.stdout.decode().strip()


def main() -> None:
    """main entry point."""
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=ArgparseFormatter)
    parser.add_argument('--outfile', metavar='FILE.prom',
                        help='Output file (stdout)', type=Path)
    parser.add_argument('-d', '--debug', action='store_true', default=False,
                        help='Enable debug logging (%(default)s)')
    parser.add_argument('--puppet-state-dir', dest='puppet_state_dir',
                        help='Puppet state directory', type=Path)
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)

    if args.outfile and args.outfile.suffix != '.prom':
        parser.error('Output file does not end with .prom')

    registry = CollectorRegistry()
    collect_puppet_stats(registry, args.puppet_state_dir)

    if args.outfile:
        # write_to_textfile calls os.rename which doesn't support Path like
        # objects until python 3.6
        # TODO: once we drop support for python3.5 drop the str cast
        write_to_textfile(str(args.outfile), registry)
    else:
        sys.stdout.write(generate_latest(registry).decode('utf-8'))


if __name__ == '__main__':
    sys.exit(main())
