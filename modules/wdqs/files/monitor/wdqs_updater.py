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
            'runner': 'Path to Jolokia runner',
            'counters': 'List of counters to collect',
            'sudo_user': 'The user to use if using sudo',
        })
        return chelp

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(WDQSUpdaterCollector, self).get_default_config()
        config.update({
            'runner':     '/srv/wdqs/blazegraph/jolokia.sh',
            'counters': ["updates/MeanRate", "batch-progress/MeanRate"],
            'sudo_user': 'blazegraph',
        })
        return config

    def start_jolokia(self):
        cmdline = ['sudo', '-u', self.config['sudo_user'],
                   '--', self.config['runner'], 'start']
        self.url = subprocess.check_output(cmdline).strip().split("\n")[-1]

    def stop_jolokia(self):
        cmdline = ['sudo', '-u', self.config['sudo_user'],
                   '--', self.config['runner'], 'stop']
        subprocess.call(cmdline)

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
        self.start_jolokia()
        try:
            for counter in self.config['counters']:
                data = self.get_data(counter)
                if data:
                    self.publish(self.query_to_metric(counter),
                                 data)
        finally:
            self.stop_jolokia()
