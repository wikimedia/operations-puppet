# -*- coding: utf-8 -*-
"""
  Diamond metric collector for RCStream

  <https://wikitech.wikimedia.org/wiki/RCStream>
  <https://github.com/BrightcoveOS/Diamond/wiki>

  Copyright 2014 Ori Livneh <ori@wikimedia.org>
  Licensed under the Apache License, Version 2.0

"""
import json
import re
import subprocess
import urllib2

import diamond.collector


class RCStreamCollector(diamond.collector.Collector):

    def discover_backends(self):
        out = subprocess.check_output(['/sbin/initctl', 'list'])
        return re.findall(r'rcstream/server \((.*)\)', out)

    def get_backend_stats(self, backend):
        resp = urllib2.urlopen('http://%s/rcstream_status' % backend)
        return json.loads(resp.read())

    def collect(self):
        stats = [self.get_backend_stats(b) for b in self.discover_backends()]

        connected_clients = sum(stat['connected_clients'] for stat in stats)
        self.publish('rcstream.connected_clients', connected_clients)

        max_queue_size = max(stat['queue_size'] for stat in stats)
        self.publish('rcstream.max_queue_size', max_queue_size)
