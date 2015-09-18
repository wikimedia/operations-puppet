# coding=utf-8

"""
2015 Chase Pettet

This is a significantly paired down
collector for the WMF scale.  The native
diamond collector has dozens of stats per
index which at our scale is impractical at
the moment.

This collector publishes a set list of metrics
and only publishes cluster metrics from the 
current master.

"""
import urllib2

try:
    import json
    json  # workaround for pyflakes issue #13
except ImportError:
    import simplejson as json

import diamond.collector


class WMFElasticCollector(diamond.collector.Collector):

    def __init__(self, *args, **kwargs):
        super(WMFElasticCollector, self).__init__(*args, **kwargs)

        self.node_id = ''

        self.endpoints = {
            'node': '_nodes/_local/stats',
            'cluster': '_cluster/stats',
        }

        # Metrics provided at cluster and node level
        # _cluster/stats
        self.cluster_metrics = [
            'indices.docs.deleted',
            'indices.docs.count',
            'indices.count',
            'indices.shards.total',
            'indices.shards.primaries',
            'indices.shards.replication',
            'indices.store.size_in_bytes',
            'indices.segments.count',
            'indices.segments.memory_in_bytes',
            'indices.segments.index_writer_max_memory_in_bytes',
            'indices.segments.version_map_memory_in_bytes',
            'indices.segments.fixed_bit_set_memory_in_bytes',
            'nodes.count.total',
            'nodes.os.mem.total_in_bytes',
            'nodes.jvm.mem.heap_used_in_bytes',
            'nodes.jvm.mem.heap_max_in_bytes',
            'nodes.jvm.threads',
            'nodes.fs.total_in_bytes',
            'nodes.fs.free_in_bytes',
            'nodes.fs.available_in_bytes',
            'nodes.fs.disk_reads',
            'nodes.fs.disk_writes',
            'nodes.fs.disk_io_op',
        ]

        # node level metrics
        # '_nodes/_local/stats'
        self.node_metrics = [
            'indices.docs.deleted',
            'indices.docs.count',
            'indices.store.size_in_bytes',
            'indices.store.throttle_time_in_millis',
            'indices.indexing.index_total',
            'indices.indexing.index_time_in_millis',
            'indices.indexing.index_current',
            'indices.indexing.delete_total',
            'indices.indexing.delete_time_in_millis',
            'indices.indexing.delete_current',
            'indices.indexing.throttle_time_in_millis',
            'indices.get.total',
            'indices.get.time_in_millis',
            'indices.get.exists_total',
            'indices.get.missing_total',
            'indices.get.missing_time_in_millis',
            'indices.get.current',
            'indices.search.open_contexts',
            'indices.search.query_total',
            'indices.search.query_time_in_millis',
            'indices.search.query_current',
            'indices.search.fetch_total',
            'indices.merges.current',
            'indices.merges.current_docs',
            'indices.merges.current_size_in_bytes',
            'indices.merges.total',
            'indices.merges.total_time_in_millis',
            'indices.merges.total_docs',
            'indices.merges.total_size_in_bytes',
            'indices.refresh.total',
            'indices.refresh.total_time_in_millis',
            'indices.flush.total',
            'indices.flush.total_time_in_millis',
            'indices.warmer.current',
            'indices.warmer.total',
            'indices.warmer.total_time_in_millis',

            'process.open_file_descriptors',

            'jvm.mem.heap_used_in_bytes',
            'jvm.mem.heap_used_percent',
            'jvm.mem.heap_committed_in_bytes',
            'jvm.mem.heap_max_in_bytes',
            'jvm.mem.non_heap_used_in_bytes',
            'jvm.mem.non_heap_committed_in_bytes',
            'jvm.threads.count',
            'jvm.threads.peak_count',
            'jvm.gc.collectors.young.collection_count',
            'jvm.gc.collectors.young.collection_time_in_millis',
            'jvm.gc.collectors.old.collection_count',
            'jvm.gc.collectors.old.collection_time_in_millis',

            'http.current_open',
            'http.total_opened',
        ]

    def get_default_config_help(self):
        config_help = super(WMFElasticCollector,
                            self).get_default_config_help()
        config_help.update({
            'host': 'localhost',
            'port': '9200',
        })
        return config_help

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(WMFElasticCollector, self).get_default_config()
        config.update({
            'host':           '127.0.0.1',
            'port':           9200,
            'path':           'elasticsearch',
            'stats':          ['node', 'cluster'],
        })
        return config

    def _get(self, path):
        url = 'http://%s:%i/%s' % (self.config['host'],
                                   self.config['port'],
                                   path)
        response = urllib2.urlopen(url)
        return json.load(response)

    def is_master(self):
        master = self._get('_cluster/state/master_node')
        if self.node_id == master['master_node']:
            return master['cluster_name']

    def dict_digger(self, depth, ddict):
        if len(depth) == 1:
            return ddict[depth[0]]
        else:
            key = depth.pop(0)
            return self.dict_digger(depth, ddict[key])

    def cluster_stats(self):
        cstats = self._get(self.endpoints['cluster'])
        gmetrics = {}
        for metric in self.cluster_metrics:
            depth = metric.split('.')
            try:
                value = self.dict_digger(depth, cstats)
                gmetrics[metric] = value
            except KeyError, e:
                pass
        return gmetrics

    def node_stats(self):
        astats = self._get(self.endpoints['node'])
        self.node_id = astats['nodes'].keys()[0]
        nodestats = astats['nodes'][self.node_id]
        gmetrics = {}
        for metric in self.node_metrics:
            depth = metric.split('.')
            try:
                value = self.dict_digger(depth, nodestats)
                gmetrics[metric] = value
            except KeyError, e:
                pass
        return gmetrics

    def collect(self):
       node_stats = self.node_stats()
       for metric, value in node_stats.iteritems():
           self.publish(metric, value)

       master = self.is_master()
       if not master:
           return

       # Set the prepend to override "servers"
       self.config['path_prefix'] = 'clusters'
       # Set the hostname to the name of the cluster
       self.config['hostname'] = master
       cluster_stats = self.cluster_stats()
       for metric, value in cluster_stats.iteritems():
           self.publish(metric, value)
