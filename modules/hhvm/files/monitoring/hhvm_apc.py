# -*- coding: utf-8 -*-
"""
  hhvm_apc.py
  ~~~~~~~~~~~

  Diamond collector for HHVM APC stats.

"""
import re
import urllib2

import diamond.collector


class HhvmApcCollector(diamond.collector.Collector):
    """Collect APC metrics from HHVM."""

    interesting_metrics = (
        'entries',
        'key_size',
        'pending_deletes_via_treadmill_size',
        'value_size',
    )

    def parse_apc_info(self, raw):
        parsed = {}
        for k, v in re.findall(r'(^[a-z ]+): (\d+)$', raw, re.M | re.I):
            k = k.lower().replace(' ', '_').replace('_count', '')
            parsed[k] = int(v)
        return parsed

    def get_default_config(self):
        config = super(HhvmApcCollector, self).get_default_config()
        config.update(url='http://localhost:9002/dump-apc-info', timeout=5,
                      path='hhvm.apc')
        return config

    def collect(self):
        req = urllib2.Request(self.config['url'])
        req.add_header('User-Agent', '%s/1.0' % __file__)
        try:
            response = urllib2.urlopen(req, None, self.config['timeout'])
            apc_info = self.parse_apc_info(response.read())
            for metric in self.interesting_metrics:
                value = apc_info.get(metric)
                if value is not None:
                    self.publish(metric, value)
        except (IOError, ValueError):
            self.log.exception('Failed to collect metrics')
