# coding=utf-8

"""
Collect connection tracking statistics from host; mostly useful in
routers but potentially valuable anywhere iptables are used to stateful
filtering.

Reports:
    - network.netfilter.conntrack_max
    - network.netfilter.conntrack_count

Adapted from PuppetAgentCollector

"""

import string
import diamond.collector


class ConntrackCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        config_help = super(ConntrackCollector,
                            self).get_default_config_help()
        return config_help

    def get_default_config(self):
        config = super(ConntrackCollector, self).get_default_config()
        return config

    def _get_sysctl(self, name):

        path = '/proc/sys/' + name.translate(string.maketrans('.', '/'))

        try:
            with open(path) as f:
                value = f.read().rstrip('\n')
            return value

        except IOError:
            return None

    def collect(self):

        value = self._get_sysctl('net.netfilter.nf_conntrack_max')
        if value is not None:
            self.publish('network.netfilter.conntrack_max', value)

        value = self._get_sysctl('net.netfilter.nf_conntrack_count')
        if value is not None:
            self.publish('network.netfilter.conntrack_count', value)
