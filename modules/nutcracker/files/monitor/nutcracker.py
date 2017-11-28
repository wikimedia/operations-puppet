# coding=utf-8
"""
  Chase Pettet 2015

  Collects nutcracker server and pool stats via stats interface

  Example output:

  nutcracker.curr_connections 57 1438286309
  nutcracker.uptime 74201 1438286309
  nutcracker.total_connections 15146322 1438286309
  nutcracker.pool.$poolname.client_err 0 1438286309
  nutcracker.pool.$poolname.fragments 0 1438286309
  nutcracker.pool.$poolname.client_connections 1 1438286309
  nutcracker.pool.$poolname.forward_error 0 1438286309
  nutcracker.pool.$poolname.client_eof 587971 1438286309
"""

import json
import re
import socket
from contextlib import closing

import diamond.collector


class NutcrackerCollector(diamond.collector.Collector):

    def __init__(self, *args, **kwargs):

        diamond.collector.Collector.__init__(self, *args, **kwargs)

        self.standard_keys = {
            'curr_connections',
            'total_connections',
            'uptime',
            'service',
            'timestamp',
            'source',
            'version'
        }

        self.server_stats = [
            'curr_connections',
            'total_connections',
            'uptime',
        ]

        self.pool_stats = [
            'client_connections',
            'forward_error',
            'client_eof',
            'client_err',
            'server_ejects',
            'fragments'
        ]

    def get_nutcracker_stats(self, port):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        with closing(sock):
            sock.connect(('', port))
            sock.settimeout(1)
            raw_data = sock.recv(65536).decode('utf-8', errors='ignore')
            sock.shutdown(socket.SHUT_RDWR)

        # does not properly escape quotation marks in server aliases.
        # https://github.com/twitter/twemproxy/issues/532
        data = re.sub(r'"("[^"]+")"(?=:)', r'\1', raw_data.strip())
        stats = json.loads(data)

        # The pool names are all the keys
        # that aren't part of standard set of keys.
        pools = self.standard_keys.symmetric_difference(stats)
        stats['pools'] = {p: stats.pop(p) for p in pools}
        return stats

    def get_default_config(self):
        """
        Returns default collector settings.
        """
        config = super(NutcrackerCollector, self).get_default_config()
        config.update({
            'path': 'nutcracker',
            'host': '127.0.0.1',
            'port': 22222,
        })
        return config

    def collect(self):
        try:
            stats = self.get_nutcracker_stats(self.config['port'])
        except socket.error:
            self.log.error("connect fail for port %s", self.config['port'])
            return

        if not stats:
            return

        metrics = {}
        for ss in self.server_stats:
            metrics[ss] = stats[ss]

        pools = stats['pools'].keys()
        for p in pools:
            for s in self.pool_stats:
                metrics["pool.%s.%s" % (p, s)] = stats['pools'][p][s]

        for stat, value in metrics.iteritems():
            self.publish(stat, value)
