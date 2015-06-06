# coding=utf-8

import diamond.collector
import urllib2
import json
import subprocess
import os

class WDQSUpdaterCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        chelp = super(WDQSUpdaterCollector, self).get_default_config_help()
        chelp.update({
            'runner': 'Path to Jolokia runner',
            'prefix': 'Metric prefix',
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
            'prefix': 'wdqs-updater',
            'counters': ["updates/MeanRate", "batch-progress/MeanRate"],
            'sudo_user': 'blazegraph',
        })
        return config

    def start_jolokia(self):
        cmdline = ['sudo', '-u', self.config['sudo_user'], '--', self.config['runner'], 'start']
        self.url = subprocess.check_output(cmdline).strip().split("\n")[-1]

    def stop_jolokia(self):
        cmdline = ['sudo', '-u', self.config['sudo_user'], '--', self.config['runner'], 'stop']
        subprocess.call(cmdline)

    def query_to_metric(self, qname):
        return self.config['prefix']+'.'+qname.replace(' ', '_').replace('/', '.')

    def get_data(self, metric):
        url = "%sread/metrics:name=%s" % (self.url, metric)
        print url
        req = urllib2.Request(url)
        response = urllib2.urlopen(req)
        print response
        data = json.loads(response.read())
        print data
        if 'value' not in data:
            return
        self.publish(self.query_to_metric(metric), data['value'])
        
    def collect(self):
        """
        Overrides the Collector.collect method
        """
        self.start_jolokia()
        try:
            for counter in self.config['counters']:
                self.get_data(counter)
        finally:
            self.stop_jolokia()
