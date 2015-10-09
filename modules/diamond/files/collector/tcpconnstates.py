# -*- coding: utf-8 -*-
"""
  Diamond collector that reports the count of TCP
  network connections by state.

  Author: Ori Livneh

"""
import collections
import re
import subprocess

import diamond.collector


class TcpConnStatesCollector(diamond.collector.Collector):
    """Diamond collector that reports the count of TCP network
    connections by state."""

    def get_default_config(self):
        config = super(TcpConnStatesCollector, self).get_default_config()
        config['path'] = 'network'
        return config

    def count_tcp_connection_states(self):
        output = subprocess.check_output(('/bin/netstat', '--tcp', '--all'))
        conn_states = re.findall(r'([A-Z_]+)\s*$', output, re.M)
        return collections.Counter(conn_states)

    def collect(self):
        conn_states = self.count_tcp_connection_states()
        for state, count in conn_states.items():
            self.publish('connections.%s' % state, count)
