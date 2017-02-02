# coding=utf-8

import datetime
import json
import urllib2
import urllib

from datetime import timedelta, tzinfo
from dateutil.parser import parse
from xml.etree import ElementTree

import diamond.collector

ZERO = timedelta(0)


class UTC(tzinfo):
    def utcoffset(self, dt):
        return ZERO

    def tzname(self, dt):
        return "UTC"

    def dst(self, dt):
        return ZERO

utc = UTC()


class BlazegraphCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        chelp = super(BlazegraphCollector, self).get_default_config_help()
        chelp.update({
            'url': 'URL of the blazegraph instance',
            'counters': 'List of counters to report',
            'sparql_endpoint': 'HTTP endpoint which can be used to query blazegraph',
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
            'sparql_endpoint': 'http://localhost:9999/bigdata/namespace/wdq/sparql',
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
            urllib.urlencode({'path': cnt_name})

        req = urllib2.Request(url)
        req.add_header('Accept', 'application/xml')
        response = urllib2.urlopen(req)

        el = ElementTree.fromstring(response.read())
        last_name = cnt_name.split('/')[-1]

        for cnt in el.getiterator('c'):
            if cnt.attrib['name'] == last_name:
                return cnt.attrib['value']
        return None

    def collect_jolokia(self):
        for counter in self.config['counters']:
            metric_name = self.query_to_metric(counter)
            metric_value = self.get_counter(counter)
            if metric_value is not None:
                self.publish(metric_name, metric_value)

    def execute_sparql(self, query):
        params = urllib.urlencode({'format': 'json', 'query': query})
        request = urllib2.Request(self.config['sparql_endpoint'] + "?" + params)
        response = urllib2.urlopen(request)
        return json.loads(response.read())

    def collect_sparql(self):
        query = """ prefix schema: <http://schema.org/>
                    SELECT * WHERE { {
                      SELECT ( COUNT( * ) AS ?count ) { ?s ?p ?o }
                    } UNION {
                      SELECT * WHERE { <http://www.wikidata.org> schema:dateModified ?y }
                    } }"""
        data = self.execute_sparql(query)
        for binding in data['results']['bindings']:
            if 'count' in binding:
                triple_count = binding['count']['value']
                self.publish('triples', triple_count)
            elif 'y' in binding:
                lastUpdated = parse(binding['y']['value'])
                lag = datetime.datetime.now(utc) - lastUpdated
                self.publish('lag', lag.total_seconds())
            else:
                raise ValueError('SPARQL binding returned with unexpected key')

    def collect(self):
        self.collect_jolokia()
        self.collect_sparql()
