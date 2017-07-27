#!/usr/bin/env python

"""
Nagios plugin alerting if the hosts known to PyBal differ from those pooled in
IPVS.

Copyright 2017 Emanuele Rocca
Copyright 2017 Wikimedia Foundation, Inc.

This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY. It
may be used, redistributed and/or modified under the terms of the GNU General
Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).
"""

import argparse
import socket
import sys

import requests

from prometheus_client.parser import text_fd_to_metric_families


class PyBalIPVSDiff(object):
    def __init__(self, argument_list):
        ap = argparse.ArgumentParser(description=__doc__)
        ap.add_argument('--pybal-url',
                        help='pybal pools instrumentation URL',
                        type=str,
                        default='http://localhost:9090/pools')
        ap.add_argument('--prometheus-url',
                        help='prometheus node exporter URL',
                        type=str,
                        default='http://localhost:9100/metrics')
        ap.add_argument('--req-timeout',
                        help='HTTP request timeout in seconds',
                        type=float,
                        default=1.0)
        self.args = ap.parse_args(argument_list)

    def get_url(self, url):
        req = requests.get(url, timeout=self.args.req_timeout)
        if req.status_code != 200:
            raise requests.exceptions.RequestException(
                "Status code %s returned while getting %s" % (req.status_code, url))
        else:
            return req

    def get_remote_hosts_ipvs(self):
        """Return the set of hostnames known to IPVS by querying
        prometheus-node-exporter. As prometheus exposes the IP addresses, use
        gethostbyaddr to get the hostnames."""
        req = self.get_url(self.args.prometheus_url)

        hosts = set()

        for metric in text_fd_to_metric_families(req.iter_lines()):
            if metric.name == "node_ipvs_backend_weight":
                for sample in metric.samples:
                    address = sample[1]['remote_address']
                    hostname = socket.gethostbyaddr(address)[0]
                    hosts.add(hostname)

        return hosts

    def get_pools_pybal(self):
        req = self.get_url(self.args.pybal_url)
        return req.iter_lines()

    def get_hosts_pybal(self, pool):
        url = "%s/%s" % (self.args.pybal_url, pool)
        req = self.get_url(url)
        for line in req.iter_lines():
            if 'enabled/up/pooled' in line:
                yield line.split(':')[0]

    def get_remote_hosts_pybal(self):
        """Return the set of hostnames known to pybal. Only return information
        about pooled hosts."""
        hosts = set()
        for pool in self.get_pools_pybal():
            for host in self.get_hosts_pybal(pool):
                hosts.add(host)

        return hosts

    def run(self):
        try:
            pybal_hosts = self.get_remote_hosts_pybal()
            ipvs_hosts = self.get_remote_hosts_ipvs()
        except requests.exceptions.RequestException as err:
            print("UNKNOWN: %s" % err)
            return 3

        if pybal_hosts - ipvs_hosts:
            print("CRITICAL: Hosts known to PyBal but not to IPVS: %s" %
                  (pybal_hosts - ipvs_hosts))
            return 2

        if ipvs_hosts - pybal_hosts:
            print("CRITICAL: Hosts in IPVS but unknown to PyBal: %s" %
                  (ipvs_hosts - pybal_hosts))
            return 2

        return 0


if __name__ == "__main__":
    check = PyBalIPVSDiff(sys.argv[1:])
    sys.exit(check.run())
