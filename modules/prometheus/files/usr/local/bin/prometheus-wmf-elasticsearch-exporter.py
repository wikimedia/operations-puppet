#!/usr/bin/python3
import argparse
import logging
import sys
import time

from prometheus_client import start_http_server, Summary
from prometheus_client.core import CounterMetricFamily, GaugeMetricFamily, REGISTRY

import requests


log = logging.getLogger(__name__)


class Connection:
    """Minimal helper class for interacting with elasticsearch"""

    # Cached responses to informational requests
    _banner = None
    _cat_master = None

    def __init__(self, base_url):
        self.base_url = base_url

    @property
    def banner(self):
        if self._banner is None:
            self._banner = self.request('/')
        return self._banner

    @property
    def cat_master(self):
        if self._cat_master is None:
            # [0] is because _cat, when returning json, always returns
            # a list. But there can be only one.
            self._cat_master = self.request('/_cat/master')[0]
        return self._cat_master

    @property
    def cluster_name(self):
        return self.banner['cluster_name']

    @property
    def node_name(self):
        return self.banner['name']

    @property
    def is_master(self):
        return self.node_name == self.cat_master['node']

    def alias_map(self, indices):
        # We use aliases for most production indices. This means we ask for
        # stats on index A, which is an alias, and elasticsearch returns stats
        # for index B, which is pointed to. We want to log the stats against
        # the alias name (A) to have long term consistent names instead of
        # whatever the concrete backing name is at the time.
        # While one alias can point to multiple indices, and multiple indices
        # can share an alias, we require the indices monitored to have a 1:1
        # mapping. This maps to our typical use case for cirrussearch indices.
        aliases = self.request('/_cat/aliases/' + ','.join(indices))
        return {alias['index']: alias['alias'] for alias in aliases}

    def request(self, path):
        url = self.base_url + path
        try:
            response = requests.get(url, headers={
                'Accept': 'application/json',
            })
        except requests.exceptions.RequestException as e:
            log.error('Encountered %s communicating with elasticsearch at %s', e, url)
            raise
        if response.status_code < 200 or response.status_code >= 300:
            log.error('Status code %d returned from elasticsearch at %s', response.status_code, url)
            raise Exception('Non-2xx status code returned from elasticsearch')
        return response.json()


def fq_name(*args):
    """Fully qualified prometheus metric name"""
    return 'elasticsearch_' + '_'.join(args)


class PrometheusWMFElasticsearchExporter(object):
    scrape_duration = Summary(
        'wmf_elasticsearch_scrape_duration_seconds', 'WMF Elasticsearch exporter scrape duration')

    latency_path = '/_nodes/latencyStats'

    def __init__(self, port, indices=None):
        self.base_url = 'http://localhost:{port}'.format(port=port)
        if indices:
            self.indices = indices
            self.index_stats_path = '/{indices}/_stats'.format(
                indices=','.join(indices))
        else:
            self.indices = None
            self.index_stats_path = None

    @scrape_duration.time()
    def collect(self):
        # Our adapter caches some requests for a simpler api,
        # Use a per-collect adapter to restrict how long caches live.
        connection = Connection(self.base_url)
        yield from self.collect_latency(connection)
        yield from self.collect_indices(connection)

    def collect_indices(self, conn):
        """Collect per-index statistics from elasticsearch

        This is a port of the exact metric names/descriptions in the
        prometheus-elasticsearch-exporter package we typically use. This was
        done for consistency, but due to our customization involving alias
        handling we can likely never switch this back.
        """
        if self.index_stats_path is None:
            return
        # This script runs on all nodes, but we don't want to collect many
        # copies of this data. We also don't want to create a ticking time bomb
        # by assigning a single machine to collect this data. The strategy is
        # to only report stats when the local node is the cluster master. This
        # may have races on master change that result in under or double
        # reporting, but it shouldn't matter.
        if not conn.is_master:
            return

        indices = conn.request(self.index_stats_path)['indices']
        aliases = conn.alias_map(self.indices)
        # Shared labels for all metrics
        global_label_names = ['cluster']
        global_label_values = [conn.cluster_name]

        def populate(metric_kind, name, desc, value_fn):
            metric = metric_kind(
                fq_name('indices', name), desc,
                labels=global_label_names + ['index'])
            for index_name, stats in indices.items():
                # Resolve any aliases we found, to log against consistent names
                index_alias = aliases.get(index_name, index_name)
                try:
                    value = value_fn(stats)
                except KeyError:
                    log.warning(
                        ('No metric returned for %s in index %s, '
                         'mismatched elasticsearch version?'),
                        name, index_name)
                    value = float('nan')
                metric.add_metric(
                    global_label_values + [index_alias],
                    value)
            return metric

        yield populate(
            GaugeMetricFamily,
            "docs_primary",
            "Count of documents with only primary shards",
            lambda x: x['primaries']['docs']['count'])

        yield populate(
            GaugeMetricFamily,
            "deleted_docs_primary",
            "Count of deleted documents with only primary shards",
            lambda x: x['primaries']['docs']['deleted'])

        yield populate(
            GaugeMetricFamily,
            "docs_total",
            "Total count of documents",
            lambda x: x['total']['docs']['count'])

        yield populate(
            GaugeMetricFamily,
            "deleted_docs_total",
            "Total count of deleted documents",
            lambda x: x['total']['docs']['deleted'])

        yield populate(
            GaugeMetricFamily,
            "store_size_bytes_primary",
            ("Current total size of stored index data in bytes"
             " with only primary shards on all nodes"),
            lambda x: x['primaries']['store']['size_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "store_size_bytes_total",
            ("Current total size of stored index data in bytes"
             " with all shards on all nodes"),
            lambda x: x['total']['store']['size_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_count_primary",
            "Current number of segments with only primary shards on all nodes",
            lambda x: x['primaries']['segments']['count'])

        yield populate(
            GaugeMetricFamily,
            "segment_count_total",
            "Current number of segments with all shards on all nodes",
            lambda x: x['total']['segments']['count'])

        yield populate(
            GaugeMetricFamily,
            "segment_memory_bytes_primary",
            "Current size of segments with only primary shards on all nodes in bytes",
            lambda x: x['primaries']['segments']['memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_memory_bytes_total",
            "Current size of segments with all shards on all nodes in bytes",
            lambda x: x['total']['segments']['memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_terms_memory_primary",
            "Current size of terms with only primary shards on all nodes in bytes",
            lambda x: x['primaries']['segments']['terms_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_terms_memory_total",
            "Current number of terms with all shards on all nodes in bytes",
            lambda x: x['total']['segments']['terms_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_fields_memory_bytes_primary",
            "Current size of fields with only primary shards on all nodes in bytes",
            lambda x: x['primaries']['segments']['stored_fields_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_fields_memory_bytes_total",
            "Current size of fields with all shards on all nodes in bytes",
            lambda x: x['total']['segments']['stored_fields_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_term_vectors_memory_primary_bytes",
            "Current size of term vectors with only primary shards on all nodes in bytes",
            lambda x: x['primaries']['segments']['term_vectors_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_term_vectors_memory_total_bytes",
            "Current size of term vectors with all shards on all nodes in bytes",
            lambda x: x['total']['segments']['term_vectors_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_norms_memory_bytes_primary",
            "Current size of norms with only primary shards on all nodes in bytes",
            lambda x: x['primaries']['segments']['norms_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_norms_memory_bytes_total",
            "Current size of norms with all shards on all nodes in bytes",
            lambda x: x['total']['segments']['norms_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_points_memory_bytes_primary",
            "Current size of points with only primary shards on all nodes in bytes",
            lambda x: x['primaries']['segments']['points_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_points_memory_bytes_total",
            "Current size of points with all shards on all nodes in bytes",
            lambda x: x['total']['segments']['points_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_doc_values_memory_bytes_primary",
            "Current size of doc values with only primary shards on all nodes in bytes",
            lambda x: x['primaries']['segments']['doc_values_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_doc_values_memory_bytes_total",
            "Current size of doc values with all shards on all nodes in bytes",
            lambda x: x['total']['segments']['doc_values_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_index_writer_memory_bytes_primary",
            "Current size of index writer with only primary shards on all nodes in bytes",
            lambda x: x['primaries']['segments']['index_writer_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_index_writer_memory_bytes_total",
            "Current size of index writer with all shards on all nodes in bytes",
            lambda x: x['total']['segments']['index_writer_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_version_map_memory_bytes_primary",
            "Current size of version map with only primary shards on all nodes in bytes",
            lambda x: x['primaries']['segments']['version_map_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_version_map_memory_bytes_total",
            "Current size of version map with all shards on all nodes in bytes",
            lambda x: x['total']['segments']['version_map_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_fixed_bit_set_memory_bytes_primary",
            "Current size of fixed bit with only primary shards on all nodes in bytes",
            lambda x: x['primaries']['segments']['fixed_bit_set_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "segment_fixed_bit_set_memory_bytes_total",
            "Current size of fixed bit with all shards on all nodes in bytes",
            lambda x: x['total']['segments']['fixed_bit_set_memory_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "completion_bytes_primary",
            "Current size of completion with only primary shards on all nodes in bytes",
            lambda x: x['primaries']['completion']['size_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "completion_bytes_total",
            "Current size of completion with all shards on all nodes in bytes",
            lambda x: x['total']['completion']['size_in_bytes'])

        yield populate(
            CounterMetricFamily,
            "search_query_time_seconds_total",
            "Total search query time in seconds",
            lambda x: x['total']['search']['query_time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "search_query_total",
            "Total number of queries",
            lambda x: x['total']['search']['query_total'])

        yield populate(
            CounterMetricFamily,
            "search_fetch_time_seconds_total",
            "Total search fetch time in seconds",
            lambda x: x['total']['search']['fetch_time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "search_fetch_total",
            "Total search fetch count",
            lambda x: x['total']['search']['fetch_total'])

        yield populate(
            CounterMetricFamily,
            "search_scroll_time_seconds_total",
            "Total search scroll time in seconds",
            lambda x: x['total']['search']['scroll_time_in_millis'] / 1000)

        yield populate(
            GaugeMetricFamily,
            "search_scroll_current",
            "Current search scroll count",
            lambda x: x['total']['search']['scroll_current'])

        yield populate(
            CounterMetricFamily,
            "search_scroll_total",
            "Total search scroll count",
            lambda x: x['total']['search']['scroll_total'])

        yield populate(
            CounterMetricFamily,
            "search_suggest_time_seconds_total",
            "Total search suggest time in seconds",
            lambda x: x['total']['search']['suggest_time_in_millis'])

        yield populate(
            CounterMetricFamily,
            "search_suggest_total",
            "Total search suggest count",
            lambda x: x['total']['search']['suggest_total'])

        yield populate(
            CounterMetricFamily,
            "indexing_index_time_seconds_total",
            "Total indexing index time in seconds",
            lambda x: x['total']['indexing']['index_time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "indexing_index_total",
            "Total indexing index count",
            lambda x: x['total']['indexing']['index_total'])

        yield populate(
            CounterMetricFamily,
            "indexing_delete_time_seconds_total",
            "Total indexing delete time in seconds",
            lambda x: x['total']['indexing']['delete_time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "indexing_delete_total",
            "Total indexing delete count",
            lambda x: x['total']['indexing']['delete_total'])

        yield populate(
            CounterMetricFamily,
            "indexing_noop_update_total",
            "Total indexing no-op update count",
            lambda x: x['total']['indexing']['noop_update_total'])

        yield populate(
            CounterMetricFamily,
            "indexing_throttle_time_seconds_total",
            "Total indexing throttle time in seconds",
            lambda x: x['total']['indexing']['throttle_time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "get_time_seconds_total",
            "Total get time in seconds",
            lambda x: x['total']['get']['time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "get_total",
            "Total get count",
            lambda x: x['total']['get']['total'])

        yield populate(
            CounterMetricFamily,
            "merge_time_seconds_total",
            "Total merge time in seconds",
            lambda x: x['total']['merges']['total_time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "merge_total",
            "Total merge count",
            lambda x: x['total']['merges']['total'])

        yield populate(
            CounterMetricFamily,
            "merge_throttle_time_seconds_total",
            "Total merge I/O throttle time in seconds",
            lambda x: x['total']['merges']['total_throttled_time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "merge_stopped_time_seconds_total",
            "Total large merge stopped time in seconds, allowing smaller merges to complete",
            lambda x: x['total']['merges']['total_stopped_time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "merge_auto_throttle_bytes_total",
            "Total bytes that were auto-throttled during merging",
            lambda x: x['total']['merges']['total_auto_throttle_in_bytes'])

        yield populate(
            CounterMetricFamily,
            "refresh_time_seconds_total",
            "Total refresh time in seconds",
            lambda x: x['total']['refresh']['total_time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "refresh_total",
            "Total refresh count",
            lambda x: x['total']['refresh']['total'])

        yield populate(
            CounterMetricFamily,
            "flush_time_seconds_total",
            "Total flush time in seconds",
            lambda x: x['total']['flush']['total_time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "flush_total",
            "Total flush count",
            lambda x: x['total']['flush']['total'])

        yield populate(
            CounterMetricFamily,
            "warmer_time_seconds_total",
            "Total warmer time in seconds",
            lambda x: x['total']['warmer']['total_time_in_millis'] / 1000)

        yield populate(
            CounterMetricFamily,
            "warmer_total",
            "Total warmer count",
            lambda x: x['total']['warmer']['total'])

        yield populate(
            CounterMetricFamily,
            "query_cache_memory_bytes_total",
            "Total query cache memory bytes",
            lambda x: x['total']['query_cache']['memory_size_in_bytes'])

        yield populate(
            GaugeMetricFamily,
            "query_cache_size",
            "Total query cache size",
            lambda x: x['total']['query_cache']['cache_size'])

        yield populate(
            CounterMetricFamily,
            "query_cache_hits_total",
            "Total query cache hits count",
            lambda x: x['total']['query_cache']['hit_count'])

        yield populate(
            CounterMetricFamily,
            "query_cache_misses_total",
            "Total query cache misses count",
            lambda x: x['total']['query_cache']['miss_count'])

        yield populate(
            CounterMetricFamily,
            "query_cache_caches_total",
            "Total query cache caches count",
            lambda x: x['total']['query_cache']['cache_count'])

        yield populate(
            CounterMetricFamily,
            "query_cache_evictions_total",
            "Total query cache evictions count",
            lambda x: x['total']['query_cache']['evictions'])

        yield populate(
            CounterMetricFamily,
            "request_cache_memory_bytes_total",
            "Total request cache memory bytes",
            lambda x: x['total']['request_cache']['memory_size_in_bytes'])

        yield populate(
            CounterMetricFamily,
            "request_cache_hits_total",
            "Total request cache hits count",
            lambda x: x['total']['request_cache']['hit_count'])

        yield populate(
            CounterMetricFamily,
            "request_cache_misses_total",
            "Total request cache misses count",
            lambda x: x['total']['request_cache']['miss_count'])

        yield populate(
            CounterMetricFamily,
            "request_cache_evictions_total",
            "Total request cache evictions count",
            lambda x: x['total']['request_cache']['evictions'])

        yield populate(
            CounterMetricFamily,
            "fielddata_memory_bytes_total",
            "Total fielddata memory bytes",
            lambda x: x['total']['fielddata']['memory_size_in_bytes'])

        yield populate(
            CounterMetricFamily,
            "fielddata_evictions_total",
            "total fielddata evictions count",
            lambda x: x['total']['fielddata']['evictions'])

    def collect_latency(self, conn):
        nodes = conn.request(self.latency_path)['nodes']

        # we only want to collect latencies for the local node, so let's
        # filter out everything else reported names are something like:
        # elastic1034-production-search-eqiad
        node_latencies = next(node['latencies'] for _, node in nodes.items()
                              if node['name'] == conn.node_name)

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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-l', '--listen', metavar='ADDRESS',
                        help='Listen on this address', default=':9109')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debug logging')
    parser.add_argument('-p', '--port', type=int, default=9200,
                        help='Elasticsearch port on localhost')
    parser.add_argument('-i', '--indices', nargs='*', default=[])
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)

    address, port = args.listen.split(':', 1)

    log.info('Starting prometheus-wmf-elasticsearch-exporter on %s:%s', address, port)

    REGISTRY.register(PrometheusWMFElasticsearchExporter(
        args.port, args.indices))
    start_http_server(int(port), addr=address)

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        return 1


if __name__ == "__main__":
    sys.exit(main())
