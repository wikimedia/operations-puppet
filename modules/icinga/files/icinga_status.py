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

import logging

from argparse import ArgumentParser
from json import dumps as json_dumps
from time import sleep

from ClusterShell.NodeSet import NodeSet, RESOLVER_NOGROUP


class IcingaStatusParseError(Exception):
    """Raised when we fail to parse the status.dat file correctly"""


class Service:
    """Object to represent an icinga services"""

    # The position in the tuple is the integer value for that state
    STATES = ('OK', 'WARNING', 'CRITICAL', 'UNKNOWN')
    CASTS = {
        'current_state': int,
    }

    def __init__(self, data):
        self.name = data['service_description']
        self.host = data['host_name']
        for key, func in Service.CASTS.items():
            data[key] = func(data[key])

        self.status = data

    def __str__(self):
        return '{s.host}->{s.name}: {s.state}'.format(s=self)

    def __json__(self):
        """Return a json representation of the service"""
        # may want to filter some of this out
        return self.__dict__

    to_json = __json__

    @property
    def state(self):
        """Return the text representation of the service current_state"""
        return Service.STATES[self.status['current_state']]

    @property
    def optimal(self):
        """Return True if the service is in the optimal state."""
        return self.status['current_state'] == 0


class Host:
    """Object to represent an icinga host"""

    # The position in the tuple is the integer value for that state
    STATES = ('UP', 'DOWN', 'UNREACHABLE')
    CASTS = {
        'current_state': int,
    }

    def __init__(self, data):
        self.name = data['host_name']
        self.services = {}
        for key, func in Host.CASTS.items():
            data[key] = func(data[key])

        self.status = data

    def __str__(self):
        return '{s.name}: state={s.state}, optimal={s.optimal}'.format(s=self)

    def __json__(self):
        """Return a json representation of the service"""
        return {
            'name': self.name,
            'state': self.state,
            'optimal': self.optimal,
            'failed_services': self.failed_services,
        }

    to_json = __json__

    @property
    def state(self):
        """Return the text representation of the host current_state"""
        return Host.STATES[self.status['current_state']]

    @property
    def optimal(self):
        """Return True if the host and all its services are in the optimal state."""
        return (sum(service.status['current_state'] for service in self.services.values())
                + self.status['current_state']) == 0

    @property
    def failed_services(self):
        """Return an list of all failed services"""
        return [service for service in self.services.values() if not service.optimal]

    def has_service(self, name):
        """Return True if the host has a service matching `name`"""
        return name in self.services

    def get_service(self, name):
        """Return the service matching `name`"""
        return self.services[name]

    def add_service(self, service):
        """Add `service` to this hosts list of services"""
        if service.host != self.name:
            raise RuntimeError(
                'Service {name} for host {host} do not match current hostname {hostname}'.format(
                    name=service.name, host=service.host, hostname=self.name))

        self.services[service.name] = service


class IcingaStatus:
    """Object to represent an icinga status.dat file"""

    def __init__(self, filename):
        try:
            with open(filename) as status_file:
                self._lines = status_file.readlines()
        except OSError as error:
            raise IcingaStatusParseError('corrupt status.dat: Failed to open file: {}'.format(
                error))

        self.hosts = {}
        self._parse_status()

    def get_host(self, name):
        """Return a Host object matching `name`"""
        return self.hosts[name]

    def get_hosts(self, names):
        """Return a dict of Hosts matching `names`"""
        return {name: self.hosts.get(name, False) for name in names}

    def get_service(self, name):
        """Return all Service objects matching `name`"""
        return [host.services[name] for host in self.hosts.values() if host.has_service(name)]

    def get_hosts_with_service(self, name):
        """Return all Host objects with a Service matching `name`"""
        return [host for host in self.hosts.values() if host.has_service(name)]

    def _add_block(self, name, data):
        if name == 'hoststatus':
            host = Host(data)
            self.hosts[host.name] = host
        elif name == 'servicestatus':
            service = Service(data)
            self.hosts[service.host].add_service(service)

    def _parse_status(self):
        block_name = None
        block = {}

        for line in self._lines:
            if line[0] in ('\n', '#'):  # Skip empty lines and comments
                continue
            elif line[0].isalpha():  # New block found
                block_name = line.split()[0]
                continue

            sline = line.strip()
            if sline == '}':
                self._add_block(block_name, block)
                block_name = None
                block = {}
                continue
            # Theses objects appear last in the file so we can exit the function
            if block_name in ('hostdowntime', 'servicedowntime'):
                return

            # Small optimization
            if block_name not in ('hoststatus', 'servicestatus'):
                continue

            # Block key=value entry
            parts = sline.split('=', 1)
            block[parts[0]] = parts[1]
        # If we get to this point we have found no downtime and likley read a corrupt file
        raise IcingaStatusParseError('corrupt status.dat: Failed to found downtime object')


def get_args():
    """Argument handler"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('hosts', help="Hosts selection query")
    parser.add_argument('-s', '--status-file', default='/var/icinga-tmpfs/status.dat')
    parser.add_argument('-v', '--verbose', action='count')
    parser.add_argument('-p', '--pretty-print', action='store_true',
                        help='pretty print json output.  Implies `--json`')
    parser.add_argument('-j', '--json', action='store_true',
                        help='print json output')
    return parser.parse_args()


def get_log_level(args_level):
    """Set logging level based on args.verbose"""
    return {
        None: logging.CRITICAL,
        1: logging.ERROR,
        2: logging.WARNING,
        3: logging.INFO,
    }.get(args_level, logging.DEBUG)


def main():
    """The main cli entry point"""
    exit_code = 0
    args = get_args()
    log_level = get_log_level(args.verbose)
    logging.basicConfig(level=log_level)

    try:
        status = IcingaStatus(args.status_file)
    except IcingaStatusParseError as error:
        logging.error('Failed to read status.dat (retrying): %s', error)
        sleep(0.5)
        status = IcingaStatus(args.status_file)

    hosts = status.get_hosts(
        [host.split('.')[0] for host in NodeSet(args.hosts, resolver=RESOLVER_NOGROUP)])

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
