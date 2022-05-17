#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Tool for reporting the difference between multiple nmap scans
"""

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# Copyright (c) 2015 Mozilla Corporation
# Author: ameihm@mozilla.com

import pickle
import os
import re
import logging

from argparse import ArgumentParser
from contextlib import contextmanager
from email.message import EmailMessage
from fcntl import flock, LOCK_EX, LOCK_NB, LOCK_UN
from pathlib import Path
from time import time
from smtplib import SMTP
from socket import getfqdn
from subprocess import CalledProcessError, DEVNULL, run


LOG = logging.getLogger(__file__)


class ScanData:
    """Class for holding scan data"""
    def __init__(self):
        self.scantime = time()
        self.hosts = {}
        self.dnsmap = {}
        self.uphosts = []
        self.downhosts = []

    def get_hosts(self):
        """return a list of hosts"""
        return list(self.hosts.keys())

    def get_host_ports(self, hostname):
        """Return a list of ports for a host"""
        return self.hosts[hostname]

    def open_exists(self, addr, port, proto):
        """check if a specific open port exists"""
        if addr not in self.hosts:
            return False
        cand = [port, proto]
        if cand not in self.hosts[addr]:
            return False
        return True

    def total_services(self):
        """Return the total number of services"""
        return sum([len(ports) for ports in self.hosts.values()])

    def add_open(self, addr, port, proto, hostname):
        """add an open port"""
        if proto not in ['tcp', 'udp']:
            raise Exception('unknown protocol %s' % proto)
        if addr not in self.hosts:
            self.hosts[addr] = []
        self.dnsmap[addr] = hostname
        self.hosts[addr].append([int(port), proto])


class Alert:
    """Class to hold alerts"""

    # pylint: disable=too-many-arguments
    def __init__(self, host, port, proto, dns, open_prev, closed_prev, statstr):
        self.host = host
        self.port = port
        self.proto = proto
        self.dns = dns
        self.open_prev = open_prev
        self.closed_prev = closed_prev
        self.statstr = statstr

    def __str__(self):
        return '%s %s %s %s %s %s %s' % (
            self.statstr, self.host,
            str(self.port), self.proto,
            str(self.open_prev), str(self.closed_prev),
            self.dns)


class ScanState:
    """Object for scan data"""
    KEEP_SCANS = 7

    def __init__(self):
        self._lastscan = None
        self._scanlist = []
        self._alerts_open = []
        self._alerts_closed = []

    def up_trend(self):
        """Print up trends"""
        ret = ''
        for i in self._scanlist:
            if len(ret) == 0:
                ret = '%d' % len(i.uphosts)
            else:
                ret += ',%d' % len(i.uphosts)
        return ret

    def down_trend(self):
        """Print down trends"""
        ret = ''
        for i in self._scanlist:
            if len(ret) == 0:
                ret = '%d' % len(i.downhosts)
            else:
                ret += ',%d' % len(i.downhosts)
        return ret

    def clear_alerts(self):
        """Clear current alerts"""
        self._alerts_open = []
        self._alerts_closed = []

    def last_scan_total_services(self):
        """Return total services for the last scan"""
        return self._lastscan.total_services()

    def previous_scan_total_services(self):
        """Return total services for the previous scan"""
        if len(self._scanlist) > 1:
            return self._scanlist[1].total_services()
        return 0

    def set_last(self, last):
        """Set the last scan"""
        self._lastscan = last
        if len(self._scanlist) == self.KEEP_SCANS:
            self._scanlist.pop()
        self._scanlist.insert(0, last)
        self.clear_alerts()

    def calculate(self):
        """Calculate open and closed ports"""
        self.calculate_new_open()
        self.calculate_new_closed()

    def prev_service_status(self, addr, port, proto):
        """Return a count of open and closed ports from previous scan"""
        openprev = 0
        closedprev = 0
        if len(self._scanlist) <= 1:
            return (0, 0)
        for scan in self._scanlist[1:]:
            if scan.open_exists(addr, port, proto):
                openprev += 1
            else:
                closedprev += 1
        return (openprev, closedprev)

    def calculate_new_open(self):
        """Calculate open ports"""
        if len(self._scanlist) <= 1:
            return
        for host in self._lastscan.get_hosts():
            for port in self._lastscan.get_host_ports(host):
                prevscan = self._scanlist[1]
                if not prevscan.open_exists(host, port[0], port[1]):
                    statstr = 'OPEN'
                    dns = self._lastscan.dnsmap[host]
                    # If this host isn't in the previous up or down list,
                    # note it as a new host
                    if (host not in prevscan.uphosts) and \
                       (host not in prevscan.downhosts):
                        statstr = 'OPENNEWHOST'
                    openprev, closedprev = \
                        self.prev_service_status(host, port[0], port[1])
                    self._alerts_open.append(Alert(
                        host, port[0], port[1], dns, openprev, closedprev, statstr))

    def calculate_new_closed(self):
        """Calculate closed ports"""
        if len(self._scanlist) <= 1:
            return
        prevscan = self._scanlist[1]
        for host in prevscan.get_hosts():
            for port in prevscan.get_host_ports(host):
                if not self._lastscan.open_exists(host, port[0], port[1]):
                    statstr = 'CLOSED'
                    # See if the host existed in the current scan, if it did
                    # use that hostname, otherwise grab previous
                    if host in self._lastscan.dnsmap:
                        dns = self._lastscan.dnsmap[host]
                    else:
                        # If we didn't have a dns map entry for it, that means
                        # the host wasn't even up, note this in the status
                        statstr = 'CLOSEDDOWN'
                        dns = prevscan.dnsmap[host]
                    openprev, closedprev = \
                        self.prev_service_status(host, port[0], port[1])
                    self._alerts_closed.append(Alert(
                        host, port[0], port[1], dns, openprev, closedprev, statstr))

    @property
    def open_alerts(self):
        """open alerts"""
        return self._alerts_open

    @property
    def closed_alerts(self):
        """closed alerts"""
        return self._alerts_closed

    def outstanding_alerts(self):
        """Check for outstanding alerts"""
        return self._alerts_open or self._alerts_closed


def get_log_level(args_level):
    """Configure logging"""
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG}.get(args_level, logging.DEBUG)


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    port_group = parser.add_mutually_exclusive_group()
    port_group.add_argument('-T', '--topports', type=int)
    port_group.add_argument('-p', '--portspec')
    parser.add_argument('-E', '--report-email')
    parser.add_argument('--min-hostgroup', type=int, default=256)
    parser.add_argument('-W', '--working-dir', default=Path.cwd(), type=Path)
    parser.add_argument('-v', '--verbose', action='count')
    parser.add_argument('targets', type=Path, help='File containing network targets')
    return parser.parse_args()


def load_scanstate(statefile):
    """load the state from the previous scan"""
    if statefile.is_file():
        LOG.debug('Load state file from: %s', statefile)
        try:
            with statefile.open('rb') as state_fh:
                return pickle.load(state_fh)
        except OSError as error:
            LOG.error('Unable to load state (%s): %s', statefile, error)
            raise SystemExit(1) from error
    LOG.debug('no previous state file: %s', statefile)
    return ScanState()


def write_scanstate(statefile, state):
    """Save scanState to pickle file"""
    LOG.debug('writing state file to: %s', statefile)
    with statefile.open('wb') as state_fh:
        pickle.dump(state, state_fh)


def parse_output(path):
    """Parse nmap output"""
    new_scan = ScanData()

    with path.open() as path_fh:
        for line in path_fh.readlines():
            line = line.strip()
            match = re.search(r'Host: (\S+) \(([^)]*)\).*Status: Up', line)
            if match is not None:
                addr = match.group(1)
                new_scan.uphosts.append(addr)
            match = re.search(r'Host: (\S+) \(([^)]*)\).*Status: Down', line)
            if match is not None:
                addr = match.group(1)
                new_scan.downhosts.append(addr)
            match = re.search(r'Host: (\S+) \(([^)]*)\).*Ports: (.*)$', line)
            if match is not None:
                addr = match.group(1)
                hostname = match.group(2)
                if len(hostname) == 0:
                    hostname = 'unknown'
                ports = [x.split('/') for x in match.group(3).split(',')]
                for port in ports:
                    if port[1] != 'open':
                        continue
                    new_scan.add_open(addr.strip(), port[0].strip(), port[2].strip(), hostname)
    return new_scan


@contextmanager
def lock_file(path):
    '''obtain an exclusive no blocking lock on file_path'''
    try:
        if not path.exists():
            path.touch()
        path_fh = path.open('r+')
        flock(path_fh, LOCK_EX | LOCK_NB)
        path_fh.seek(0)
        path_fh.write('file locked by {} - PID:{}'.format(os.environ['USER'], os.getpid()))
        path_fh.truncate()
        path_fh.flush()
        yield path_fh
    except BlockingIOError as error:
        raise SystemExit('{}\n{}'.format(error, path_fh.read())) from error
    except OSError as error:
        raise SystemExit('failed to acquire lock on: {}\n{}'.format(path_fh, error)) from error
    finally:
        flock(path_fh, LOCK_UN)
        path_fh.close()


def get_nmap_args(args, outfile):
    """Return a list of nmap args based on the diffscan args"""
    nmap_args = ['nmap', '-vv', '-sS', '-PE', '-PS22,25,80,443,3306,8443,9100',
                 '-T4', '--privileged', '--defeat-rst-ratelimit']
    nmap_args += ['--min-hostgroup', str(args.min_hostgroup)]
    if args.portspec:
        nmap_args += ['-p', str(args.portspec)]
    else:
        topports = args.topports if args.topports else 2000
        nmap_args += ['--top-ports', str(topports)]
    nmap_args += ['-iL', str(args.targets)]
    nmap_args += ['-oG', str(outfile)]
    return nmap_args


def report(state):
    """produce output"""
    return """
New Open Service List
---------------------
STATUS HOST PORT PROTO OPREV CPREV DNS
{open_alerts}

New Closed Service List
---------------------
STATUS HOST PORT PROTO OPREV CPREV DNS
{closed_alerts}

OPREV: number of times service was open in last {max_scans}
CPREV number of times service was closed in last {max_scans}:
current total services: {curent_total_services}
previous total services: {previous_total_services}
up trend: {up_trend}
down trend: {down_trend}""".format(
        open_alerts='\n'.join(str(alert) for alert in state.open_alerts),
        closed_alerts='\n'.join(str(alert) for alert in state.closed_alerts),
        max_scans=state.KEEP_SCANS,
        curent_total_services=state.last_scan_total_services(),
        previous_total_services=state.previous_scan_total_services(),
        up_trend=state.up_trend(),
        down_trend=state.down_trend())


def send_email(recipient, subject, body, server='localhost'):
    """Send the body in an email to the recipient with subject"""
    msg = EmailMessage()
    msg['From'] = 'diffscan2 <noreply@{}>'.format(getfqdn())
    msg['To'] = recipient
    msg['Subject'] = subject
    msg.set_content(body)
    smtp = SMTP(server)
    smtp.send_message(msg)
    smtp.quit()


def main():
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    LOG.setLevel(get_log_level(args.verbose))

    base_dir = args.working_dir
    outdir = base_dir / 'diffscan_out'
    lockfile = base_dir / 'diffscan.lock'
    statefile = base_dir / 'diffscan.state'

    try:
        outdir.mkdir(0o770, True, True)
    except OSError as error:
        LOG.error('unable to create %s: %s', base_dir, error)
        return 1

    outfile = outdir / 'nmap-{}-{}.out'.format(int(time()), os.getpid())
    nmap_args = get_nmap_args(args, outfile)
    LOG.debug('nmap args: %s', ' '.join(nmap_args))
    state = load_scanstate(statefile)

    with lock_file(lockfile):
        try:
            run(nmap_args, stdout=DEVNULL, check=True)
        except CalledProcessError as error:
            LOG.error('nmap failed to run: %s', error)
            outfile.unlink()
            return 1
        new_scan = parse_output(outfile)
        state.set_last(new_scan)
        state.calculate()
        write_scanstate(statefile, state)
    if args.report_email and state.outstanding_alerts():
        send_email(args.report_email, args.targets.name, report(state))
    else:
        print(report(state))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
