'''
Collect request status code metrics from etherad

#### Dependencies

 * subprocess
'''

from diamond.collector import Collector
import urllib2
import json


class EtherpadStatusCollector(Collector):

    def get_default_config(self):
        '''
        Returns the default collector settings
        '''
        config = super(EtherpadStatusCollector, self).get_default_config()
        config.update({
            'url': 'http://localhost:9001/stats',
            'gauges': ['memoryUsage', 'totalUsers', 'pendingEdits'],
            'counters': [
                'connects/count',
                'disconnects/count',
                'httpRequests/meter/count',
                'edits/meter/count',
                'failedChangesets/meter/count',
            ],
        })
        return config

    def collect(self):
        '''
        Publishes stats to the configured path.
        '''
        url = urllib2.urlopen(self.config['url'])
        if url.code != 200:
            return
        stats = json.loads(url.read())
        for gauge in self.config['gauges']:
            self.publish_gauge(gauge, stats[gauge])
        # Use the / character as a split character
        for counter in self.config['counters']:
            name = counter.replace('/', '_')
            parts = counter.split('/')
            t = stats
            for part in parts:
                t = t.get(part)
            self.publish_counter(name, t)
