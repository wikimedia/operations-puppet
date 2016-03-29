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
        try:
            # Output example 'net.netfilter.nf_conntrack_count = 130698'
            output = subprocess.check_output(
                ['/sbin/sysctl', 'net.netfilter.nf_conntrack_count'],
                stderr=subprocess.STDOUT
            )
            return int(output.split("=")[1].strip())
        except subprocess.CalledProcessError:
            # sysctl can raise an exception if the ip_conntrack_count
            # is not set, for example on systems without ferm/conntrack.
            return 0

    def collect(self):
        count = self.count_nf_connections_tracked()
        self.publish('nf_conntrack_count', count)
