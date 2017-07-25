#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Nagios plugin alerting if the hosts known to PyBal differ from those pooled in
IPVS.

Copyright 2017 Emanuele Rocca
Copyright 2017 Wikimedia Foundation, Inc.

This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.  It
may be used, redistributed and/or modified under the terms of the GNU General
Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).
"""

import argparse
import sets
import socket
import sys
import urlparse

import requests

from prometheus_client.parser import text_fd_to_metric_families


class PyBalIPVSDiff(object):
    def __init__(self, argument_list):
        ap = argparse.ArgumentParser(description=__doc__)
        ap.add_argument('--pybal-url', help='pybal pools instrumentation URL',
                        type=str, default='http://localhost:9090/pools')
        ap.add_argument('--prometheus-url', help='prometheus node exporter URL',
                        type=str, default='http://localhost:9100/metrics')
        self.args = ap.parse_args(argument_list)

    def get_remote_hosts_ipvs(self):
        """Return the set of hostnames known to IPVS by querying
        prometheus-node-exporter. As prometheus exposes the IP addresses, use
        gethostbyaddr to get the hostnames."""
        req = requests.get(self.args.prometheus_url)

        hosts = []

        for metric in text_fd_to_metric_families(req.text.split('\n')):
            if metric.name == "node_ipvs_backend_weight":
                for sample in metric.samples:
                    address = sample[1]['remote_address']
                    hostname = socket.gethostbyaddr(address)[0]
                    hosts.append(hostname)

        return sets.Set(hosts)

    def get_pools_pybal(self):
        req = requests.get(self.args.pybal_url)
        return req.text.split('\n')

    def get_hosts_pybal(self, pool):
        url = urlparse.urljoin(self.args.pybal_url, '/pools/%s' % pool)
        req = requests.get(url)
        for host in req.text.split('\n'):
            host_data = host.split()
            if len(host_data) < 2:
                continue

            if host_data[1] == 'enabled/up/pooled':
                yield host_data[0].replace(':', '')

    def get_remote_hosts_pybal(self):
        """Return the set of hostnames known to pybal. Only return information
        about pooled hosts."""
        hosts = []
        for pool in self.get_pools_pybal():
            for host in self.get_hosts_pybal(pool):
                hosts.append(host)

        return sets.Set(hosts)

    def run(self):
        pybal_hosts = self.get_remote_hosts_pybal()
        ipvs_hosts = self.get_remote_hosts_ipvs()

        if pybal_hosts - ipvs_hosts:
            print("CRITICAL: Hosts known to PyBal but not to IPVS:",
                  pybal_hosts - ipvs_hosts)
            sys.exit(2)

        if ipvs_hosts - pybal_hosts:
            print("CRITICAL: Hosts in IPVS but unknown to PyBal:",
                  ipvs_hosts - pybal_hosts)
            sys.exit(2)

        sys.exit(0)


if __name__ == "__main__":
    PyBalIPVSDiff(sys.argv[1:]).run()
