#!/usr/bin/env python2

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
import urllib2

from ConfigParser import SafeConfigParser
from prometheus_client.parser import text_fd_to_metric_families


class PyBalIPVSDiff(object):
    def __init__(self, argument_list):
        ap = argparse.ArgumentParser(description=__doc__)
        ap.add_argument(
            '--pybal-url',
            help='pybal pools instrumentation URL',
            type=str,
            default='http://localhost:9090/pools',
        )
        ap.add_argument(
            '--prometheus-url',
            help='prometheus node exporter URL',
            type=str,
            default='http://localhost:9100/metrics',
        )
        ap.add_argument(
            '--req-timeout',
            help='HTTP request timeout in seconds',
            type=float,
            default=1.0,
        )
        ap.add_argument(
            '--pybal-config',
            help='pybal config file path',
            type=str,
            default='/etc/pybal/pybal.conf',
        )
        self.args = ap.parse_args(argument_list)

    def get_url(self, url):
        try:
            req = urllib2.urlopen(url, timeout=self.args.req_timeout)
        except urllib2.HTTPError as e:
            print(
                "UNKNOWN: Status code %s returned while getting %s" % (e.getcode(), url)
            )
            return 3
        else:
            return req.read()

    def get_remote_hosts_ipvs(self):
        """Return the set of hostnames known to IPVS by querying
        prometheus-node-exporter. As prometheus exposes the IP addresses, use
        gethostbyaddr to get the hostnames."""
        req = self.get_url(self.args.prometheus_url)

        hosts = set()

        for metric in text_fd_to_metric_families(req.splitlines()):
            if metric.name == "node_ipvs_backend_weight":
                for sample in metric.samples:
                    address = sample[1]['remote_address']
                    hostname = socket.gethostbyaddr(address)[0]
                    hosts.add(hostname)

        return hosts

    def get_pools_pybal(self):
        req = self.get_url(self.args.pybal_url)
        return req.splitlines()

    def get_hosts_pybal(self, pool):
        url = "%s/%s" % (self.args.pybal_url, pool)
        req = self.get_url(url)
        for line in req.splitlines():
            if line.endswith('/pooled'):
                yield line.split(':')[0]

    def get_remote_hosts_pybal(self):
        """Return the set of hostnames known to pybal. Only return information
        about pooled hosts."""
        hosts = set()
        for pool in self.get_pools_pybal():
            for host in self.get_hosts_pybal(pool):
                hosts.add(host)

        return hosts

    def get_services_pybal(self):
        """Return the set of ip:port services known to pybal."""
        services = set()
        pybal_config = SafeConfigParser()
        pybal_config.read(self.args.pybal_config)

        for section in pybal_config.sections():
            if section == 'global':
                continue
            service = '{}:{}'.format(
                pybal_config.get(section, 'ip'), pybal_config.get(section, 'port')
            )
            services.add(service)

        return services

    def get_services_ipvs(self):
        """Return the set of ip:port services known to IPVS."""
        req = self.get_url(self.args.prometheus_url)
        services = set()

        for metric in text_fd_to_metric_families(req.splitlines()):
            if metric.name == "node_ipvs_backend_weight":
                for sample in metric.samples:
                    address = sample[1]['local_address']
                    port = sample[1]['local_port']
                    services.add('{}:{}'.format(address, port))

        return services

    def run(self):
        try:
            pybal_hosts = self.get_remote_hosts_pybal()
            ipvs_hosts = self.get_remote_hosts_ipvs()
            ipvs_services = self.get_services_ipvs()
            pybal_services = self.get_services_pybal()
        except urllib2.HTTPError as err:
            print("UNKNOWN: %s" % err)
            return 3

        error_msg = []

        if pybal_services - ipvs_services:
            error_msg.append(
                "Services known to PyBal but not to IPVS: {}".format(
                    pybal_services - ipvs_services
                )
            )

        if ipvs_services - pybal_services:
            error_msg.append(
                "Services in IPVS but unknown to PyBal: {}".format(
                    ipvs_services - pybal_services
                )
            )
        if pybal_hosts - ipvs_hosts:
            error_msg.append(
                "Hosts known to PyBal but not to IPVS: {}".format(
                    pybal_hosts - ipvs_hosts
                )
            )

        if ipvs_hosts - pybal_hosts:
            error_msg.append(
                "Hosts in IPVS but unknown to PyBal: {}".format(
                    ipvs_hosts - pybal_hosts
                )
            )

        if error_msg:
            print("CRITICAL: Mismatch between IPVS and PyBal\n", "\n".join(error_msg))
            return 2

        print("OK: no difference between hosts in IPVS/PyBal")
        return 0


if __name__ == "__main__":
    check = PyBalIPVSDiff(sys.argv[1:])
    sys.exit(check.run())
