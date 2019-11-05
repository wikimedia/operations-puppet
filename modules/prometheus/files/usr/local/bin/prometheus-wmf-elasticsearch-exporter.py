#!/usr/bin/python3
import argparse
import logging
import socket
import sys
import time

from prometheus_client import start_http_server, Summary
from prometheus_client.core import GaugeMetricFamily, REGISTRY

import requests


log = logging.getLogger(__name__)


class PrometheusWMFElasticsearchExporter(object):

    scrape_duration = Summary(
        'wmf_elasticsearch_scrape_duration_seconds', 'WMF Elasticsearch exporter scrape duration')

    def __init__(self, port):
        self.base_url = "http://localhost:{port}".format(port=port)
        self.latency_url = "{base_url}/_nodes/latencyStats".format(base_url=self.base_url)

    @scrape_duration.time()
    def collect(self):
        try:
            response = requests.get(self.latency_url)
            nodes = response.json()['nodes']
            hostname = socket.gethostname()

            # we only want to collect latencies for the local node, so let's
            # filter out everything else reported names are something like:
            # elastic1034-production-search-eqiad
            node_latencies = next(node['latencies'] for _, node in nodes.items()
                                  if node['name'].startswith(hostname))

            per_node_latency = GaugeMetricFamily('elasticsearch_per_node_latency',
                                                 'Per node latency percentiles',
                                                 labels=['bucket', 'percentile'])

            for handler, latencies in node_latencies.items():
                for latency in latencies:
                    per_node_latency.add_metric(
                        [handler, str(latency['percentile'])],
                        latency['latencyMs']
                    )
            yield per_node_latency
        except requests.exceptions.RequestException as e:
            log.error('Encountered %s while querying %s', e, self.latency_url)
            return


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-l', '--listen', metavar='ADDRESS',
                        help='Listen on this address', default=':9109')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debug logging')
    parser.add_argument('-p', '--port', type=int, default=9200,
                        help='Elasticsearch port on localhost')
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
