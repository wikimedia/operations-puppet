# coding=utf-8
"""
Requires:

sudo for runner script
"""

import diamond.collector
import urllib2
import json
import subprocess


class WDQSUpdaterCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        chelp = super(WDQSUpdaterCollector, self).get_default_config_help()
        chelp.update({
            'counters': 'List of counters to collect',
            'port': 'Jolokia port',
        })
        return chelp

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(WDQSUpdaterCollector, self).get_default_config()
        config.update({
            'counters': ["updates/Count", "batch-progress/Count"],
            'port': 8778,
        })
        return config

    def query_to_metric(self, qname):
        return qname.replace(' ', '_').replace('/', '.')

    def get_data(self, metric):
        url = "%sread/metrics:name=%s" % (self.url, metric)
        req = urllib2.Request(url)
        response = urllib2.urlopen(req)
        data = json.loads(response.read())
        if 'value' in data:
            return data['value']
        self.log.error("No value found in data")

    def collect(self):
        self.url = "http://localhost:%d/jolokia/" % self.config['port']
        for counter in self.config['counters']:
            data = self.get_data(counter)
            if data:
                self.publish(self.query_to_metric(counter), data)
