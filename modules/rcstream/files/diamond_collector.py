# -*- coding: utf-8 -*-
"""
  Diamond metric collector for RCStream

  <https://wikitech.wikimedia.org/wiki/RCStream>
  <https://github.com/BrightcoveOS/Diamond/wiki>

  Copyright 2014 Ori Livneh <ori@wikimedia.org>
  Licensed under the Apache License, Version 2.0

"""
import json
import urllib2

import diamond.collector


class RCStreamCollector(diamond.collector.Collector):

    def get_default_config(self):
        config = super(RCStreamCollector, self).get_default_config()
        config['backends'] = '127.0.0.1:10080'
        return config

    def get_default_config_help(self):
        help = super(RCStreamCollector, self).get_default_config_help()
        help['backends'] = 'Comma-separated backend addresses (host:port)'
        return help

    def get_backend_stats(self, backend, timeout=2):
        if ':' not in backend:
            backend = '127.0.0.1:' + backend  # assume it's a port number.
        url = 'http://%s/rcstream_status' % backend
        resp = urllib2.urlopen(url, timeout=timeout)
        return json.loads(resp.read())

    def collect(self):
        stats = []
        backends = self.config['backends'].split(',')
        for backend in backends:
            try:
                stat = self.get_backend_stats(backend)
            except (IOError, ValueError):
                self.log.exception('Failed to check backend %s', backend)
            else:
                stats.append(stat)
        connected_clients = sum(stat['connected_clients'] for stat in stats)
        self.publish('rcstream.connected_clients', connected_clients)

        max_queue_size = max(stat['queue_size'] for stat in stats)
        self.publish('rcstream.max_queue_size', max_queue_size)
