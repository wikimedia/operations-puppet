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

import logging
import os
import pickle
import re

from argparse import ArgumentParser
from collections import deque, namedtuple
from contextlib import contextmanager
from email.message import EmailMessage
from fcntl import flock, LOCK_EX, LOCK_NB, LOCK_UN
from itertools import islice
from pathlib import Path
from smtplib import SMTP
from socket import getfqdn
from subprocess import CalledProcessError, DEVNULL, run
from time import time

LOG = logging.getLogger(__file__)
# TODO: move to a dataclass
Service = namedtuple("Service", ("address", "port", "protocol"))


class Host:
    """Class to represent a scanned host."""

    def __init__(self, address: str, is_up: bool, *, hostname: str = "unknown") -> None:
        self.address = address  # optionally make those private and add a @property
        self.hostname = hostname
        self.up = is_up  # pylint: disable=invalid-name
        self.services: set[Service] = set()

    def __str__(self) -> str:
        """Return the address."""
        return self.address

    def __eq__(self, other) -> bool:
        """Return the address."""
        return self.__dict__ == other.__dict__

    def add(self, service: Service) -> None:
        """Add a service."""
        self.services.add(service)

    def is_open(self, service: Service) -> bool:
        """Indicate if a port is open"""
        return service in self.services

    @property
    def total_services(self) -> int:
        """Return the number of open services"""
        return len(self.services)


class ScanData:
    """Class for holding scan data"""

    def __init__(self) -> None:
        self.scantime = time()
        self.hosts: dict[str, Host] = {}

    @property
    def total_services(self) -> int:
        """Return the total number of services"""
        return sum(host.total_services for host in self.hosts.values())

    @property
    def hostnames(self) -> list:
        """Return a list of hosts"""
        return list(str(host.hostname) for host in self.hosts.values())

    def add_host(self, address: str, is_up: bool, hostname: str) -> None:
        """Add a new host to the scan data."""
        self.hosts[address] = Host(address, is_up, hostname=hostname)

    def add_open(self, address: str, port: int, proto: str) -> None:
        """add an open port"""
        service = Service(address, int(port), proto)
        self.hosts[service.address].add(service)


class Alert:
    """Class to hold alerts"""

    # TODO: Convert to dataclass once py3.5 support dropped (aka debian > stretch)
    def __init__(
        self, service: Service, open_prev: int, closed_prev: int, statstr: str, dns: str
    ) -> None:
        self.service = service
        self.open_prev = open_prev
        self.closed_prev = closed_prev
        self.statstr = statstr
        self.dns = dns

    def __str__(self) -> str:
        return "%s %s %s %s %s %s %s" % (
            self.statstr,
            self.service.address,
            str(self.service.port),
            self.service.protocol,
            str(self.open_prev),
            str(self.closed_prev),
            self.dns,
        )


class ScanState:
    """Object for scan data"""

    KEEP_SCANS = 7

    def __init__(self):
        self._lastscan = None
        self._scanlist = deque(maxlen=self.KEEP_SCANS)
        self._alerts = []

    def up_trend(self):
        """Print up trends"""
        counts = []
        for scan in self._scanlist:
            # Count the number of up hosts in this scan
            up_hosts = [host for host in scan.hosts.values() if host.up]
            counts.append(str(len(up_hosts)))
        return ",".join(counts)

    def down_trend(self):
        """Print down trends"""
        counts = []
        for scan in self._scanlist:
            # Count the number of down hosts in this scan
            down_hosts = [host for host in scan.hosts.values() if not host.up]
            counts.append(str(len(down_hosts)))
        return ",".join(counts)

    def clear_alerts(self):
        """Clear current alerts"""
        self._alerts = []

    def last_scan_total_services(self):
        """Return total services for the last scan"""
        return self._lastscan.total_services

    def previous_scan_total_services(self):
        """Return total services for the previous scan"""
        if len(self._scanlist) > 1:
            return self._scanlist[1].total_services
        return 0

    def set_last(self, last):
        """Set the last scan"""
        self._lastscan = last
        self._scanlist.appendleft(last)
        self.clear_alerts()

    def prev_service_status(self, address: str, service: Service) -> tuple:
        """return account for how many times a port was open or closed in the historical reports
        Arguments:
            address (str): a string representing the address of the host
            service (Service): the service to check for

        Returns:
            tuple(int, int): representing how many times the port was observed open or closed in
                the historical reports
        """
        openprev = 0
        closedprev = 0
        if len(self._scanlist) <= 1:
            return (0, 0)
        for scan in islice(self._scanlist, 1, None):
            if address not in scan.hosts:
                continue
            if scan.hosts[address].is_open(service):
                openprev += 1
            else:
                closedprev += 1
        return (openprev, closedprev)

    def calculate(self):
        """Calculate open and closed ports"""
        if len(self._scanlist) <= 1:
            return
        curr_hosts = self._lastscan.hosts
        prev_hosts = self._scanlist[1].hosts

        # New hosts (did not appear in previous scan)
        for host in curr_hosts.keys() - prev_hosts.keys():
            _host = curr_hosts[host]
            for service in _host.services:
                openprev, closedprev = self.prev_service_status(host, service)
                self._alerts.append(
                    Alert(service, openprev, closedprev, "OPENNEWHOST", _host.hostname)
                )

        # Old hosts (in previous scan but not current)
        for host in prev_hosts.keys() - curr_hosts.keys():
            _host = prev_hosts[host]
            for service in _host.services:
                openprev, closedprev = self.prev_service_status(host, service)
                self._alerts.append(
                    Alert(service, openprev, closedprev, "CLOSEDDOWN", _host.hostname)
                )

        # hosts in both scans
        for host in prev_hosts.keys() & curr_hosts.keys():
            prev_host = prev_hosts[host]
            curr_host = curr_hosts[host]
            if prev_host == curr_host:
                # Scan data is the same, we don't care so continue
                continue
            for service in curr_host.services:
                openprev, closedprev = self.prev_service_status(host, service)
                # port is closed in current scan
                if prev_host.is_open(service) and not curr_host.is_open(service):
                    self._alerts.append(
                        Alert(
                            service, openprev, closedprev, "CLOSED", curr_host.hostname
                        )
                    )
                    continue
                # port is open in current scan
                if not prev_hosts[host].is_open(service) and curr_hosts[host].is_open(
                    service
                ):
                    self._alerts.append(
                        Alert(service, openprev, closedprev, "OPEN", curr_host.hostname)
                    )

    @property
    def open_alerts(self):
        """open alerts"""
        return [alert for alert in self._alerts if alert.statstr.startswith("OPEN")]

    @property
    def closed_alerts(self):
        """closed alerts"""
        return [alert for alert in self._alerts if alert.statstr.startswith("CLOSED")]

    def outstanding_alerts(self):
        """Check for outstanding alerts"""
        return any(self._alerts)


def get_log_level(args_level):
    """Configure logging"""
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    port_group = parser.add_mutually_exclusive_group()
    port_group.add_argument("-T", "--topports", type=int)
    port_group.add_argument("-p", "--portspec")
    parser.add_argument("-E", "--report-email")
    parser.add_argument("--min-hostgroup", type=int, default=256)
    parser.add_argument("-W", "--working-dir", default=Path.cwd(), type=Path)
    parser.add_argument("-v", "--verbose", action="count")
    parser.add_argument("targets", type=Path, help="File containing network targets")
    return parser.parse_args()


def load_scanstate(statefile):
    """load the state from the previous scan"""
    if not statefile.is_file():
        LOG.debug("no previous state file: %s", statefile)
        return ScanState()
    LOG.debug("Load state file from: %s", statefile)
    try:
        with statefile.open("rb") as state_fh:
            return pickle.load(state_fh)
    except OSError as error:
        LOG.error("Unable to load state (%s): %s", statefile, error)
        raise SystemExit(1) from error


def write_scanstate(statefile, state):
    """Save scanState to pickle file"""
    LOG.debug("writing state file to: %s", statefile)
    with statefile.open("wb") as state_fh:
        pickle.dump(state, state_fh)


def parse_output(path):
    """Parse nmap output"""
    new_scan = ScanData()
    search_str = re.compile(
        r"Host:\s(?P<ip>[^\s]+)\s+"
        r"\((?P<hostname>[^\)]*)?\)\s+"
        r"(?P<action>Status|Ports):\s+"
        r"(?P<value>.*)"
    )

    with path.open() as path_fh:
        for line in path_fh.readlines():
            line = line.strip()
            match = re.search(search_str, line)
            if match is None:
                continue
            hostname = match["hostname"] if match["hostname"] else "unknown"
            if match["action"] == "Status":
                is_up = match["value"] == "Up"
                new_scan.add_host(match["ip"], is_up, hostname)
                continue
            if match["action"] == "Ports":
                if "/" not in match["value"]:
                    # If no / that means there are no open port found
                    continue
                ports = [x.split("/") for x in match["value"].split(",")]
                for port in ports:
                    if port[1] != "open":
                        continue
                    new_scan.add_open(match["ip"], port[0].strip(), port[2].strip())
    return new_scan


@contextmanager
def lock_file(path):
    """obtain an exclusive no blocking lock on file_path"""
    try:
        if not path.exists():
            path.touch()
        path_fh = path.open("r+")
        flock(path_fh, LOCK_EX | LOCK_NB)
        path_fh.seek(0)
        path_fh.write(
            "file locked by {} - PID:{}".format(os.environ["USER"], os.getpid())
        )
        path_fh.truncate()
        path_fh.flush()
        yield path_fh
    except BlockingIOError as error:
        raise SystemExit("{}\n{}".format(error, path_fh.read())) from error
    except OSError as error:
        raise SystemExit(
            "failed to acquire lock on: {}\n{}".format(path_fh, error)
        ) from error
    finally:
        flock(path_fh, LOCK_UN)
        path_fh.close()


def get_nmap_args(args, outfile):
    """Return a list of nmap args based on the diffscan args"""
    nmap_args = [
        "nmap",
        "-vv",
        "-sS",
        "-PE",
        "-PS22,25,80,443,3306,8443,9100",
        "-T4",
        "--privileged",
        "--defeat-rst-ratelimit",
    ]
    nmap_args += ["--min-hostgroup", str(args.min_hostgroup)]
    if args.portspec:
        nmap_args += ["-p", str(args.portspec)]
    else:
        topports = args.topports if args.topports else 2000
        nmap_args += ["--top-ports", str(topports)]
    nmap_args += ["-iL", str(args.targets)]
    nmap_args += ["-oG", str(outfile)]
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
        open_alerts="\n".join(str(alert) for alert in state.open_alerts),
        closed_alerts="\n".join(str(alert) for alert in state.closed_alerts),
        max_scans=state.KEEP_SCANS,
        curent_total_services=state.last_scan_total_services(),
        previous_total_services=state.previous_scan_total_services(),
        up_trend=state.up_trend(),
        down_trend=state.down_trend(),
    )


def send_email(recipient, subject, body, server="localhost"):
    """Send the body in an email to the recipient with subject"""
    msg = EmailMessage()
    msg["From"] = "diffscan2 <noreply@{}>".format(getfqdn())
    msg["To"] = recipient
    msg["Subject"] = subject
    msg["Auto-Submitted"] = "auto-generated"
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
    outdir = base_dir / "diffscan_out"
    lockfile = base_dir / "diffscan.lock"
    statefile = base_dir / "diffscan.state"

    try:
        outdir.mkdir(0o770, True, True)
    except OSError as error:
        LOG.error("unable to create %s: %s", base_dir, error)
        return 1

    outfile = outdir / "nmap-{}-{}.out".format(int(time()), os.getpid())
    nmap_args = get_nmap_args(args, outfile)
    LOG.debug("nmap args: %s", " ".join(nmap_args))
    state = load_scanstate(statefile)

    with lock_file(lockfile):
        try:
            run(nmap_args, stdout=DEVNULL, check=True)
        except CalledProcessError as error:
            LOG.error("nmap failed to run: %s", error)
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


if __name__ == "__main__":
    raise SystemExit(main())
