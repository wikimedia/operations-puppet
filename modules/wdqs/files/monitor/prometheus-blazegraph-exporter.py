#!/usr/bin/python3
# Copyright 2017 Moritz Muehlenhoff
#                Filippo Giunchedi
#                Wikimedia Foundation
# Copyright 2015 Stanislav Malyshev
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import logging
import sys
import time
import requests

from dateutil.parser import parse
from xml.etree import ElementTree

from prometheus_client import start_http_server, Summary
from prometheus_client.core import CounterMetricFamily, GaugeMetricFamily, REGISTRY

log = logging.getLogger(__name__)


class PrometheusBlazeGraphExporter(object):

    scrape_duration = Summary(
        'blazegraph_scrape_duration_seconds', 'Blazegraph exporter scrape duration')

    def __init__(self, blazegraph_port):

        self.url = 'http://localhost:{port}/bigdata'.format(port=blazegraph_port)
        self.counters = []
        self.sparql_endpoint = '{base_url}/namespace/wdq/sparql'.format(base_url=self.url)

    def query_to_metric(self, qname):
        return qname.replace(' ', '_').replace('/', '.').lstrip('.')

    def get_counter(self, cnt_name):
        # Not sure why we need depth but some counters don't work without it
        url = '{base_url}/counters?depth=10&path={cnt_name}'.format(
                    base_url=self.url, cnt_name=cnt_name
        )

        try:
            header = {'Accept': 'application/xml'}
            response = requests.get(url, headers=header)
        except requests.exceptions.RequestException:
            log.exception('Error sending request')
            return None

        el = ElementTree.fromstring(response.content)
        last_name = cnt_name.split('/')[-1]

        for cnt in el.getiterator('c'):
            if cnt.attrib['name'] == last_name:
                return cnt.attrib['value']
        return None

    def execute_sparql(self, query):
        params = {'format': 'json', 'query': query}
        response = requests.get(self.sparql_endpoint, params=params)
        return response.json()

    @scrape_duration.time()
    def collect(self):
        blazegraph_metrics = {
            '/Query Engine/queryStartCount': CounterMetricFamily(
                    'blazegraph_queries_start',
                    'Number of queries that have started since the start of the application.'
            ),
            '/Query Engine/queryDoneCount': CounterMetricFamily(
                    'blazegraph_queries_done',
                    'Number of queries completed since the start of the application.'
            ),
            '/Query Engine/queryErrorCount': CounterMetricFamily(
                    'blazegraph_queries_error',
                    'Number of queries in error since the start of the application.'
            ),
            '/Query Engine/queriesPerSecond': GaugeMetricFamily(
                    'blazegraph_queries_per_second',
                    'Number of queries per second (rolling average).'
            ),
            '/Query Engine/operatorActiveCount': GaugeMetricFamily(
                    'blazegraph_operator_active_count',
                    'Number of active blazegraph operators'
            ),
            '/Query Engine/runningQueriesCount': GaugeMetricFamily(
                    'blazegraph_running_queries_count',
                    'Number of running queries'
            ),
            '/Query Engine/GeoSpatial/geoSpatialSearchRequests': GaugeMetricFamily(
                'blazegraph_geospatial_search_requets',
                'Number of geospatial search requests since the start of the application.'),

            '/Journal/bytesReadPerSec': GaugeMetricFamily(
                'blazegraph_journal_bytes_read_per_second',
                ''
            ),
            '/Journal/bytesWrittenPerSec': GaugeMetricFamily(
                'blazegraph_journal_bytes_written_per_second',
                ''
            ),
            '/Journal/extent': GaugeMetricFamily(
                'blazegraph_journal_extent',
                ''
            ),
            '/Journal/commitCount': CounterMetricFamily(
                'blazegraph_journal_commit_count',
                ''
            ),
            '/Journal/commit/totalCommitSecs': GaugeMetricFamily(
                'blazegraph_journal_total_commit_seconds',
                'Total time spent in commit.'
            ),
            '/Journal/commit/flushWriteSetSecs': GaugeMetricFamily(
                'blazegraph_journal_flush_write_set_seconds',
                ''
            ),
            '/Journal/Concurrency Manager/Read Service/Average Active Count': GaugeMetricFamily(
                'blazegraph_journal_concurrency_read_average_active_count',
                'Average Number of Read Active Threads'
            ),
            '/JVM/Memory/DirectBufferPool/default/bytesUsed': GaugeMetricFamily(
                'blazegraph_jvm_memory_direct_buffer_pool_default_bytes_used',
                ''
            ),
            '/JVM/Memory/Runtime Free Memory': GaugeMetricFamily(
                'blazegraph_jvm_memory_runtime_free_memory',
                'Current amount of free memory in the JVM.'
            ),
            '/JVM/Memory/Runtime Max Memory': GaugeMetricFamily(
                'blazegraph_jvm_memory_runtime_max_memory',
                'Max amount of memory the JVM can allocate.'
            ),
            '/JVM/Memory/Runtime Total Memory': GaugeMetricFamily(
                'blazegraph_jvm_memory_runtime_total_memory',
                'Total amount of memory allocated to the JVM.'
            ),
            '/JVM/Memory/Garbage Collectors/G1 Old Generation/Collection Count':
                CounterMetricFamily(
                'blazegraph_jvm_memory_gc_g1_old_collecton_count',
                'Number of old GC since JVM start.'
                ),
            '/JVM/Memory/Garbage Collectors/G1 Old Generation/Cumulative Collection Time':
                GaugeMetricFamily(
                    'blazegraph_jvm_memory_gc_g1_old_cumulative_collection_time',
                    'Total time spent in old GC (seconds).'
                ),
            '/JVM/Memory/Garbage Collectors/G1 Young Generation/Collection Count':
                CounterMetricFamily(
                    'blazegraph_jvm_memory_gc_g1_young_collection_count',
                    'Number of young GC since JVM start.'
                ),
            '/JVM/Memory/Garbage Collectors/G1 Young Generation/Cumulative Collection Time':
                GaugeMetricFamily(
                    'blazegraph_jvm_memory_gc_g1_young_cumulative_collection_time',
                    'Total time spent in young GC (seconds).'
                ),
        }

        for metric_name, metric_family in blazegraph_metrics.items():
            if metric_name is None:
                log.warning('Unknown metric %r', metric_name)
            else:
                metric_value = self.get_counter(metric_name)

                try:
                    value = float(metric_value)
                except (ValueError, TypeError):
                    value = float('nan')

                metric_family.add_metric([], value)

        triple_metric = CounterMetricFamily('blazegraph_triples', '')
        lag_metric = CounterMetricFamily('blazegraph_lastupdated', '')
        try:
            sparql_query = """ prefix schema: <http://schema.org/>
                        SELECT * WHERE { {
                          SELECT ( COUNT( * ) AS ?count ) { ?s ?p ?o }
                        } UNION {
                          SELECT * WHERE { <http://www.wikidata.org> schema:dateModified ?y }
                        } }"""

            data = self.execute_sparql(sparql_query)

            for binding in data['results']['bindings']:
                if 'count' in binding:
                    triple_count = binding['count']['value']
                    triple_metric.add_metric([], float(triple_count))

                elif 'y' in binding:
                    lastUpdated = parse(binding['y']['value'])
                    lag_metric.add_metric([], float(lastUpdated.strftime('%s')))
                else:
                    raise ValueError('SPARQL binding returned with unexpected key')

        except requests.exceptions.RequestException:
            log.exception("Error querying endpoint")
            triple_metric.add_metric([], float('nan'))
            lag_metric.add_metric([], float('nan'))
        yield triple_metric
        yield lag_metric

        for metric in blazegraph_metrics.values():
            yield metric


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-l', '--listen', metavar='ADDRESS',
                        help='Listen on this address', default=':9193')
    parser.add_argument('-p', '--port', metavar='PORT',
                        help='Blazegraph port to query for metrics', default='9999', type=int)
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debug logging')
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)

    address, listen_port = args.listen.split(':', 1)

    log.info('Starting blazegraph_exporter on %s:%s', address, listen_port)

    REGISTRY.register(PrometheusBlazeGraphExporter(args.port))
    start_http_server(int(listen_port), addr=address)

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        return 1


if __name__ == "__main__":
    sys.exit(main())
