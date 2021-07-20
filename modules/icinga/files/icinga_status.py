#!/usr/bin/env python3
"""A quick Nagios status.dat file parser"""
# Copyright 2019 Wikimedia Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import logging

from json import dumps as json_dumps
from pathlib import Path
from time import sleep
from typing import Any, Dict, List, Optional, Set, Tuple, Union, cast

from ClusterShell.NodeSet import NodeSet, RESOLVER_NOGROUP


class IcingaStatusParseError(Exception):
    """Raised when we fail to parse the status.dat file correctly"""


class Service:
    """Object to represent an icinga services"""

    # The position in the tuple is the integer value for that state
    STATES = ('OK', 'WARNING', 'CRITICAL', 'UNKNOWN')
    CASTS = {
        'current_state': int,
        'scheduled_downtime_depth': int,
        'notifications_enabled': bool,
    }

    def __init__(self, data: Dict[str, str]):
        self.name = data['service_description']
        self.host = data['host_name']
        for key, func in Service.CASTS.items():
            data[key] = func(data[key])
        self.status = cast(Dict[str, Any], data)

    def __str__(self) -> str:
        return '{s.host}->{s.name}: {s.state}'.format(s=self)

    def __json__(self) -> Dict[str, Any]:
        """Return a json representation of the service"""
        # may want to filter some of this out
        return self.__dict__

    to_json = __json__

    @property
    def state(self) -> str:
        """Return the text representation of the service current_state"""
        return Service.STATES[self.status['current_state']]

    @property
    def optimal(self) -> bool:
        """Return True if the service is in the optimal state."""
        return self.status['current_state'] == 0

    @property
    def downtimed(self) -> bool:
        return bool(self.status['scheduled_downtime_depth'])

    @property
    def notifications_enabled(self) -> bool:
        return self.status['notifications_enabled']


class Host:
    """Object to represent an icinga host"""

    # The position in the tuple is the integer value for that state
    STATES = ('UP', 'DOWN', 'UNREACHABLE')
    CASTS = {
        'current_state': int,
        'scheduled_downtime_depth': int,
        'notifications_enabled': bool,
    }

    def __init__(self, data: Dict[str, str]):
        self.name = data['host_name']
        self.services: Dict[str, Service] = {}
        for key, func in Host.CASTS.items():
            data[key] = func(data[key])

        self.status = cast(Dict[str, Any], data)

    def __str__(self) -> str:
        return '{s.name}: state={s.state}, optimal={s.optimal}, downtime={s.downtimed}'.format(
            s=self)

    def __json__(self) -> Dict[str, Union[str, bool, List[Service]]]:
        """Return a json representation of the service"""
        return {
            'name': self.name,
            'state': self.state,
            'optimal': self.optimal,
            'failed_services': self.failed_services,
            'downtimed': self.downtimed,
            'notifications_enabled': self.notifications_enabled,
        }

    to_json = __json__

    @property
    def state(self) -> str:
        """Return the text representation of the host current_state"""
        return Host.STATES[self.status['current_state']]

    @property
    def optimal(self) -> bool:
        """Return True if the host and all its services are in the optimal state."""
        return (sum(service.status['current_state'] for service in self.services.values())
                + self.status['current_state']) == 0

    @property
    def failed_services(self) -> List[Service]:
        """Return an list of all failed services"""
        return [service for service in self.services.values() if not service.optimal]

    @property
    def downtimed(self) -> bool:
        return bool(self.status['scheduled_downtime_depth'])

    @property
    def notifications_enabled(self) -> bool:
        return self.status['notifications_enabled']

    def has_service(self, name: str) -> bool:
        """Return True if the host has a service matching `name`"""
        return name in self.services

    def get_service(self, name: str) -> Service:
        """Return the service matching `name`"""
        return self.services[name]

    def add_service(self, service: Service) -> None:
        """Add `service` to this hosts list of services"""
        if service.host != self.name:
            raise RuntimeError(
                'Service {name} for host {host} do not match current hostname {hostname}'.format(
                    name=service.name, host=service.host, hostname=self.name))

        self.services[service.name] = service


class IcingaStatus:
    """Object to represent an icinga status.dat file"""

    def __init__(self, status_path: Path, target_hostnames: Set[str]):
        try:
            status_text = status_path.read_text()
        except OSError as error:
            raise IcingaStatusParseError('corrupt status.dat: Failed to open file: {}'.format(
                error))

        self.hosts: Dict[str, Host] = {}
        self._target_hostnames = target_hostnames
        self._parse_status(status_text)

    def get_host(self, name: str) -> Host:
        """Return a Host object matching `name`"""
        return self.hosts[name]

    def get_hosts(self) -> Dict[str, Union[Host, bool]]:
        """Return a dict of Hosts matching `target_hostnames` given in __init__"""
        return {name: self.hosts.get(name, False) for name in self._target_hostnames}

    def get_downtimed_hosts(self) -> Dict[str, Host]:
        """Return a dict of the current hosts that have scheduled downtime"""
        return {k: v for k, v in self.hosts.items() if v.downtimed}

    def get_service(self, name: str) -> List[Service]:
        """Return all Service objects matching `name`"""
        return [host.services[name] for host in self.hosts.values() if host.has_service(name)]

    def get_hosts_with_service(self, name: str) -> List[Host]:
        """Return all Host objects with a Service matching `name`"""
        return [host for host in self.hosts.values() if host.has_service(name)]

    def _parse_status(self, status_text: str) -> None:
        # The status file is several million lines long, consisting of blocks that start with
        # "BLOCK_NAME {", contain "\tKEY=VALUE" lines, and end with "\t}". For performance reasons,
        # rather than iterating on the status file line-by-line, we instead start by splitting it
        # into those blocks so that we can parse each of them individually. (Some blocks will also
        # have leading blank lines, and/or comments.)
        #
        # The reason that's so much faster is that most blocks describe hosts (or services on hosts)
        # that weren't listed on the command line, so we're never going to read them. Splitting this
        # way means that we can immediately bail out of those blocks and skip to the next.
        blocks = status_text.split('\n\t}\n')
        for block in blocks:
            name, data = self._parse_block(block)
            # These objects appear last in the file so we can exit the function
            if name in {'hostdowntime', 'servicedowntime'}:
                return
            if not data:
                continue
            if name == 'hoststatus':
                host = Host(data)
                self.hosts[host.name] = host
            elif name == 'servicestatus':
                service = Service(data)
                self.hosts[service.host].add_service(service)
        # If we get to this point we have found no downtime and likely read a corrupt file
        raise IcingaStatusParseError('corrupt status.dat: Failed to find downtime object')

    def _parse_block(self, block: str) -> Tuple[str, Optional[Dict[str, str]]]:
        name = None
        data = {}
        for line in block.splitlines():
            if not line or line[0] == '#':  # Skip empty lines and comments.
                continue
            if line[0] != '\t':  # Found the start of the block.
                name = line[:-2]  # Strip off the trailing " {"
                if name not in {'hoststatus', 'servicestatus'}:
                    # Not a block type we're interested in, skip the whole thing.
                    return name, None
                continue
            sline = line[1:]  # Strip off the leading tab.
            key, value = sline.split('=', 1)
            if key == 'host_name' and value not in self._target_hostnames:
                # Not a host we're interested in, skip it. Cast away the Optional from the block
                # name, since we've always set it before we reach the host_name.
                return cast(str, name), None
            data[key] = value
        # The split() function in _parse_status removed the trailing "}", so as soon as we run out
        # of lines, we've finished the block.
        return cast(str, name), data


def get_args() -> argparse.Namespace:
    """Argument handler"""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('hosts', help="Hosts selection query")
    parser.add_argument('-s', '--status-file', type=Path,
                        default=Path('/var/icinga-tmpfs/status.dat'))
    parser.add_argument('-v', '--verbose', action='count')
    parser.add_argument('-p', '--pretty-print', action='store_true',
                        help='pretty print json output.  Implies `--json`')
    parser.add_argument('-j', '--json', action='store_true',
                        help='print json output')
    parser.add_argument('--verbatim-hosts', action='store_true',
                        help=('Treat the hosts parameter as verbatim Icinga hostnames, without '
                              'extracting the hostname from the FQDN.'))
    return parser.parse_args()


def get_log_level(args_level: Optional[int]) -> int:
    """Set logging level based on args.verbose"""
    return {
        None: logging.CRITICAL,
        1: logging.ERROR,
        2: logging.WARNING,
        3: logging.INFO,
    }.get(args_level, logging.DEBUG)


def main() -> int:
    """The main cli entry point"""
    exit_code = 0
    args = get_args()
    log_level = get_log_level(args.verbose)
    logging.basicConfig(level=log_level)

    hosts_nodeset = NodeSet(args.hosts, resolver=RESOLVER_NOGROUP)
    if args.verbatim_hosts:
        hosts_set = set(hosts_nodeset)
    else:
        hosts_set = {host.split('.')[0] for host in hosts_nodeset}

    try:
        icinga_status = IcingaStatus(args.status_file, hosts_set)
    except IcingaStatusParseError as error:
        logging.error('Failed to read status.dat (retrying): %s', error)
        sleep(0.5)
        icinga_status = IcingaStatus(args.status_file, hosts_set)

    hosts = icinga_status.get_hosts()

    for host, status in hosts.items():
        if status is False:
            exit_code = 1
            logging.error('%s: Not Found', host)
            continue
        if not status.optimal:
            logging.error('%s, %s', host, [str(srv) for srv in status.failed_services])
            exit_code = 1

    if args.pretty_print:
        print(json_dumps(hosts, sort_keys=True, indent=4, default=lambda o: o.to_json()))
    elif args.json:
        print(json_dumps(hosts, default=lambda o: o.to_json()))
    return exit_code


if __name__ == '__main__':
    raise SystemExit(main())
