# coding=utf-8

import diamond.collector
import urllib2
from xml.etree import ElementTree
from urllib import urlencode


class BlazegraphCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        chelp = super(BlazegraphCollector, self).get_default_config_help()
        chelp.update({
            'url': 'URL of the blazegraph instance',
            'counters': 'List of counters to report',
        })
        return chelp

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(BlazegraphCollector, self).get_default_config()
        config.update({
            'url': 'http://localhost:9999/bigdata/',
            'counters': ["/Query Engine/queryDoneCount"],
        })
        return config

    def process_config(self):
        super(BlazegraphCollector, self).process_config()
        if isinstance(self.config['counters'], basestring):
            self.config['counters'] = [self.config['counters']]

    def query_to_metric(self, qname):
        return qname.replace(' ', '_').replace('/', '.').lstrip('.')

    def get_counter(self, cnt_name):
        # Not sure why we need depth but some counters don't work without it
        url = self.config['url'] + "counters?depth=10&" + \
            urlencode({'path': cnt_name})

        req = urllib2.Request(url)
        req.add_header('Accept', 'application/xml')
        response = urllib2.urlopen(req)

        el = ElementTree.fromstring(response.read())
        last_name = cnt_name.split('/')[-1]

        for cnt in el.getiterator('c'):
            if cnt.attrib['name'] == last_name:
                return cnt.attrib['value']
        return None

    def collect(self):
        for counter in self.config['counters']:
            metric_name = self.query_to_metric(counter)
            metric_value = self.get_counter(counter)
            if metric_value is not None:
                self.publish(metric_name, metric_value)
