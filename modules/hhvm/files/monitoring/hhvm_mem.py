#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  Ganglia metric-gathering module for HHVM memory stats

"""
import json
import re
import sys
import time
import urllib2


def flatten(mapping, prefix=''):
    flat = {}
    for k, v in mapping.items():
        k = prefix + re.sub('\W', '', k.replace(' ', '_'))
        flat.update(flatten(v, k + '.') if isinstance(v, dict) else {k: v})
    return flat


class MemoryStats(object):
    def __init__(self, url, expiry=5):
        self.url = url
        self.expiry = expiry
        self.data = {}
        self.update()

    def update(self):
        req = urllib2.urlopen(self.url)
        res = flatten(json.load(req)['Memory'], 'HHVM.')
        self.data.update(res)
        self.last_fetched = time.time()

    def expired(self):
        return time.time() - self.last_fetched > self.expiry

    def get(self, stat):
        if self.expired():
            self.update()
        return self.data[stat]


def metric_init(params):
    url = params.get('url', 'http://localhost:9002/memory.json')
    stats = MemoryStats(url)
    return [{
        'name': str(key),
        'value_type': 'uint',
        'format': '%u',
        'units': 'count' if 'count' in key.lower() else 'bytes',
        'slope': 'both',
        'groups': 'HHVM',
        'call_back': stats.get,
    } for key in stats.data]


def metric_cleanup():
    pass


def self_test():
    params = dict(arg.split('=') for arg in sys.argv[1:])
    metrics = metric_init(params)
    while 1:
        for metric in metrics:
            name = metric['name']
            call_back = metric['call_back']
            print '%s: %s' % (name, call_back(name))
        time.sleep(5)


if __name__ == '__main__':
    self_test()
