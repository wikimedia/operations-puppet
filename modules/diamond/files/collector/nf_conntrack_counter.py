# -*- coding: utf-8 -*-
"""
  Diamond collector that reports the count of connections
  tracked by netfilter (nf_conntrack_count).
"""

import subprocess
import diamond.collector


class NfConntrackCountCollector(diamond.collector.Collector):
    """Diamond collector that reports the count of the count
    of connections tracked by netfilter."""

    def get_default_config(self):
        config = super(NfConntrackCountCollector, self).get_default_config()
        config['path'] = 'network'
        return config

    def count_nf_connections_tracked(self):
        # Output example 'net.ipv4.netfilter.ip_conntrack_count = 130698'
        output = subprocess.check_output(
            ['/sbin/sysctl', 'net.ipv4.netfilter.ip_conntrack_count'])
        return int(output.split("=")[1].strip())

    def collect(self):
        count = self.count_nf_connections_tracked()
        self.publish('nf_conntrack_count', count)
