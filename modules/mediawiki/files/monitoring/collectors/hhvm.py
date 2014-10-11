# -*- coding: utf-8 -*-
"""
  Diamond collector for HHVM

"""
import json
import urllib2

import diamond.collector


class hhvmHealthCollector(diamond.collector.Collector):
    """Collect health metrics from HHVM."""

    def get_default_config(self):
        config = super(hhvmHealthCollector, self).get_default_config()
        config.update(url='http://localhost:9002/check-health', timeout=5)
        return config

    def collect(self):
        req = urllib2.Request(self.config['url'])
        req.add_header('User-Agent', 'diamond-hhvm-collector/1.0')
        try:
            response = urllib2.urlopen(req, None, self.config['timeout'])
            data = json.load(response)
            for key, val in data.items():
                self.publish(key, val)
        except (IOError, ValueError):
            self.log.exception('Failed to collect metrics')
