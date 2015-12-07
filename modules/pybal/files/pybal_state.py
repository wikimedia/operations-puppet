# -*- coding: utf-8 -*-
"""
  pybal_state.py
  ~~~~~~~~~~~

  Diamond collector for PyBal State.

"""
import json
import re
import requests

import diamond.collector


class PyBalStateCollector(diamond.collector.Collector):
    """Collect pool stats from PyBal"""

    UA = 'PyBalState/1.0 (Diamond collector)'
    pools_path = '/pools'

    def __init__(self, *args, **kwargs):
        super(PyBalStateCollector, self).__init__(*args, **kwargs)
        self.config['path_prefix'] = 'pybal'
        self.base_url = 'http://localhost:{}{}'.format(
            self.config['port'],
            self.pools_path)
        self.session = requests.Session()
        self.session.headers.update(
            {'Accept': 'application/json', 'User-Agent': self.UA})

    def get_default_config(self):
        default = {
            'port': 9090,
        }
        config = super(PyBalStateCollector, self).get_default_config()
        default.update(config)
        return default

    def get_default_config_help(self):
        config_help = super(PyBalStateCollector,
                            self).get_default_config_help()
        config_help.update({
            'port': 'The port configured in pybal',
        })
        return config_help

    def get_pools(self):
        r = self.session.get(self.base_url)
        return r.json()

    def collect_pool(self, name, data):
        total = len(data)
        if total == 0:
            return
        self.publish('pools.{}.total'.format(name), total)
        for k, v in data.items():
            acc = {u'pooled': 0, u'enabled': 0, u'up': 0}
            del v['weight']
            for label, val in v.items():
                if val:
                    acc[label] += 1
            for metric, count in acc.items():
                path = 'pools.{}.{}'.format(name, metric)
                self.publish(path, count)
                self.publish(path + ".ratio", count / total)

    def collect(self):
        for pool in self.get_pools():
            url = "{}/{}".format(self.base_url, pool)
            r = self.session.get(url).json()
            self.collect_pool(pool, r)
