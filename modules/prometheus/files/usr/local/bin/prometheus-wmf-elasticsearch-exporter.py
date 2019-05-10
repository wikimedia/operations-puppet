#!/usr/bin/python
import argparse
import json
import logging
import socket
import sys
import time

from urllib2 import Request, URLError, urlopen

from prometheus_client import start_http_server, Summary
from prometheus_client.core import GaugeMetricFamily, REGISTRY

log = logging.getLogger(__name__)


class PrometheusWMFElasticsearchExporter(object):

    scrape_duration = Summary(
        'wmf_elasticsearch_scrape_duration_seconds', 'WMF Elasticsearch exporter scrape duration')

    def __init__(self, elasticsearch_port):
        self.base_url = 'http://localhost:%d' % (elasticsearch_port)
        self.latency_url = self.base_url + '/_nodes/latencyStats'

    @scrape_duration.time()
    def collect(self):
        try:
            req = Request(self.latency_url)
            response = urlopen(req)
            data = json.load(response)
            hostname = socket.gethostname()
            nodes = data['nodes']

            # we only want to collect latencies for the local node, so let's
            # filter out everything else reported names are something like:
            # elastic1034-production-search-eqiad
            latencies = next(n['latencies'] for _, n in nodes.iteritems() if
                             n['name'].startswith(hostname))

            per_node_latency = GaugeMetricFamily('elasticsearch_per_node_latency',
                                                 'Per node latency percentiles',
                                                 labels=['bucket', 'percentile'])

            for handler, latency in latencies.iteritems():
                for lat in latency:
                    per_node_latency.add_metric([handler, str(lat['percentile'])], lat['latencyMs'])
            yield per_node_latency
        except URLError:
            return


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-l', '--listen', metavar='ADDRESS',
                        help='Listen on this address', default=':9109')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debug logging')
    parser.add_argument('-p', '--port', type=int, default=9200,
                        help='Port to connect to elasticsearch on localhost')
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)

    address, port = args.listen.split(':', 1)

    log.info('Starting prometheus-wmf-elasticsearch-exporter on %s:%s', address, port)

    REGISTRY.register(PrometheusWMFElasticsearchExporter(args.port))
    start_http_server(int(port), addr=address)

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        return 1


if __name__ == "__main__":
    sys.exit(main())
