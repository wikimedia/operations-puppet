# coding=utf-8
"""
Requires:

sudo for runner script
"""

import datetime
import diamond.collector
import urllib2
import urllib
import json


class WDQSUpdaterCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        chelp = super(WDQSUpdaterCollector, self).get_default_config_help()
        chelp.update({
            'counters': 'List of counters to collect',
            'port': 'Jolokia port',
            'sparql_endpoint': 'HTTP endpoint which can be used to query blazegraph',
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
            'sparql_endpoint': 'http://localhost:8888/sparql',
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

    def collect_jolokia(self):
        self.url = "http://localhost:%d/jolokia/" % self.config['port']
        for counter in self.config['counters']:
            data = self.get_data(counter)
            if data:
                self.publish(self.query_to_metric(counter), data)

    def execute_sparql(self, query):
        params = urllib.urlencode({ 'format': 'json', 'query': query})
        request = urllib2.Request(self.config['sparql_endpoint'] + "?" + params)
        response = urllib2.urlopen(request)
        return json.loads(response.read())

    def collect_sparql(self):
        # WDQS currently caches for 120 seconds, avoid this by adding whitespace
        whitespace = "" * datetime.datetime.now().minute
        query = """ prefix schema: <http://schema.org/>
                    SELECT * WHERE { {
                      SELECT ( COUNT( * ) AS ?count ) { ?s ?p ?o }
                    } UNION {
                      SELECT * WHERE { <http://www.wikidata.org> schema:dateModified ?y }
                    } %s }""" % whitespace
        data = self.execute_sparql(query)
        for binding in data['results']['bindings']:
            if 'count' in binding:
                triple_count = binding['count']['value']
                self.publish('wikidata.query.triples.TODO', triple_count)
            elif 'y' in binding:
                lastUpdated = binding['y']['value']
                lag = time() - strtotime( $lastUpdated )
                self.publish("wikidata.query.lag.TODO', $lag );
            } else {
                trigger_error( "SPARQL binding returned with unexpected keys " . json_encode( $binding ), E_USER_WARNING );
            }


    def collect(self):
            self.collect_jolokia()
            self.collect_sparql()
