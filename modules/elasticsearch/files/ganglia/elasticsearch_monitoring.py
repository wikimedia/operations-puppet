#! /usr/bin/python

"""
Elasticsearch ganglia monitoring originally from
https://github.com/ganglia/gmond_python_modules/tree/master/elasticsearch
and heavily hacked.
"""

try:
    import simplejson as json
    assert json  # silence pyflakes
except ImportError:
    import json

import socket
import threading
import time
import urllib2
from Queue import Queue
from functools import partial

URLOPEN_TIMEOUT = 4


# Used to merge stat descriptions
def merge(skel, stat):
    d = skel.copy()
    d.update(stat)
    return d

# Maximum time to server stale stats
LAST_FETCH_THRESHOLD = 600

# Stat types
GAUGE = {
    'slope': 'both',
}
BYTES_GAUGE = merge(GAUGE, {
    'units': 'bytes'
})

COUNTER = {
    'slope': 'positive',
}
TIME = merge(COUNTER, {
    'units': 'ms/sec',
})
BYTES = merge(COUNTER, {
    'units': 'bytes/sec',
})


# Stats to be collected
main_stats = dict()
# CACHE
main_stats['es_filter_cache_size'] = merge(BYTES_GAUGE, {
    'path': 'indices.filter_cache.memory_size_in_bytes',
    'description': 'Filter Cache Size'
})
main_stats['es_filter_cache_evictions'] = merge(COUNTER, {
    'path': 'indices.filter_cache.evictions',
    'description': 'Filter Cache Evictions/sec',
})
main_stats['es_id_cache_size'] = merge(BYTES_GAUGE, {
    'path': 'indices.id_cache.memory_size_in_bytes',
    'description': 'Id Cache Size',
})
main_stats['es_fielddata_cache_size'] = merge(BYTES_GAUGE, {
    'path': 'indices.fielddata.memory_size_in_bytes',
    'description': 'Field Data Cache Size'
})
main_stats['es_fielddata_cache_evictions'] = merge(COUNTER, {
    'path': 'indices.fielddata.evictions',
    'units': 'evictions/sec',
    'description': 'Field Data Cache Evictions/sec',
})

# DOCS
main_stats['es_docs_count'] = merge(GAUGE, {
    'path': 'indices.docs.count',
    'units': 'docs',
    'description': 'Documents',
})
main_stats['es_docs_deleted'] = merge(GAUGE, {
    'path': 'indices.docs.deleted',
    'units': 'docs',
    'description': 'Deleted Documents',
})

# FLUSH
main_stats['es_flushes'] = merge(COUNTER, {
    'path': 'indices.flush.total',
    'units': 'flushes',
    'description': 'Flushes/sec',
})
main_stats['es_flush_time'] = merge(TIME, {
    'path': 'indices.flush.total_time_in_millis',
    'description': 'Flush Time/sec'
})

# GET
main_stats['es_gets'] = merge(COUNTER, {
    'path': 'indices.get.total',
    'units': 'gets/sec',
    'description': 'Gets/sec',
})
main_stats['es_get_time'] = merge(TIME, {
    'path': 'indices.get.time_in_millis',
    'description': 'Get Time/sec'
})
main_stats['es_gets_exists'] = merge(COUNTER, {
    'path': 'indices.get.exists_total',
    'units': 'get/sec',
    'description': 'Get (exists)/sec',
})
main_stats['es_get_exists_time'] = merge(TIME, {
    'path': 'indices.get.exists_time_in_millis',
    'description': 'Get (exists) Time/sec'
})
main_stats['es_gets_missing'] = merge(COUNTER, {
    'path': 'indices.get.missing_total',
    'units': 'get/sec',
    'description': 'Gets (missing)/sec',
})
main_stats['es_get_missing_time'] = merge(TIME, {
    'path': 'indices.get.missing_time_in_millis',
    'description': 'Gets (missing) Time/sec'
})

# INDEXING
main_stats['es_deletes'] = merge(COUNTER, {
    'path': 'indices.indexing.delete_total',
    'units': 'deletes/sec',
    'description': 'Deletes/sec',
})
main_stats['es_delete_time'] = merge(TIME, {
    'path': 'indices.indexing.delete_time_in_millis',
    'description': 'Delete Time/sec'
})
main_stats['es_indexes'] = merge(COUNTER, {
    'path': 'indices.indexing.index_total',
    'units': 'indexes/sec',
    'description': 'Indexes Requests/sec',
})
main_stats['es_index_time'] = merge(TIME, {
    'path': 'indices.indexing.index_time_in_millis',
    'description': 'Index Time/sec'
})

# MERGES
main_stats['es_merges'] = merge(COUNTER, {
    'path': 'indices.merges.total',
    'units': 'merges/sec',
    'description': 'Merges/sec',
})
main_stats['es_merge_time'] = merge(TIME, {
    'path': 'indices.merges.total_time_in_millis',
    'description': 'Merge Time/sec'
})
main_stats['es_merge_data'] = merge(BYTES, {
    'path': 'indices.merges.total_size_in_bytes',
    'description': 'Bytes/sec'
})

# REFRESH
main_stats['es_refreshes'] = merge(COUNTER, {
    'path': 'indices.refresh.total',
    'units': 'refreshes/sec',
    'description': 'Refreshes/sec',
})
main_stats['es_refresh_time'] = merge(TIME, {
    'path': 'indices.refresh.total_time_in_millis',
    'description': 'Refresh Time/sec'
})

# WARMER
main_stats['es_warmers'] = merge(COUNTER, {
    'path': 'indices.warmer.total',
    'units': 'warmers/sec',
    'description': 'Warmers/sec',
})
main_stats['es_warmer_time'] = merge(TIME, {
    'path': 'indices.warmer.total_time_in_millis',
    'description': 'Warmer Time/sec'
})

# SEARCH
main_stats['es_queries'] = merge(COUNTER, {
    'path': 'indices.search.query_total',
    'units': 'queries/sec',
    'description': 'Queries/sec',
})
main_stats['es_query_time'] = merge(TIME, {
    'path': 'indices.search.query_time_in_millis',
    'description': 'Query Time/sec'
})
main_stats['es_fetches'] = merge(COUNTER, {
    'path': 'indices.search.fetch_total',
    'units': 'fetches/sec',
    'description': 'Fetches/sec',
})
main_stats['es_fetch_time'] = merge(TIME, {
    'path': 'indices.search.fetch_time_in_millis',
    'description': 'Fetch Time/sec'
})

# STORE
main_stats['es_indices_size'] = merge(BYTES_GAUGE, {
    'path': 'indices.store.size_in_bytes',
    'description': 'Indices Size'
})
main_stats['es_indices_throttle_time'] = merge(TIME, {
    'path': 'indices.store.throttle_time_in_millis',
    'description': 'Throttle Time/sec'
})

# JVM METRICS #
# MEM
main_stats['es_heap_committed'] = merge(BYTES_GAUGE, {
    'path': 'jvm.mem.heap_committed_in_bytes',
    'description': 'Java Heap Committed (Bytes)',
})
main_stats['es_heap_used'] = merge(BYTES_GAUGE, {
    'path': 'jvm.mem.heap_used_in_bytes',
    'description': 'Java Heap Used (Bytes)',
})
main_stats['es_non_heap_committed'] = merge(BYTES_GAUGE, {
    'path': 'jvm.mem.non_heap_committed_in_bytes',
    'description': 'Java Non Heap Committed (Bytes)',
})
main_stats['es_non_heap_used'] = merge(BYTES_GAUGE, {
    'path': 'jvm.mem.non_heap_used_in_bytes',
    'description': 'Java Non Heap Used (Bytes)',
})

# MEMORY POOLS
for name in ['young', 'survivor', 'old']:
    main_stats['es_' + name + '_heap_used'] = merge(BYTES_GAUGE, {
        'path': 'jvm.mem.pools.' + name + '.used_in_bytes',
        'description': name.capitalize() + ' Generation Used (Bytes)',
    })
    main_stats['es_' + name + '_heap_max'] = merge(BYTES_GAUGE, {
        'path': 'jvm.mem.pools.' + name + '.max_in_bytes',
        'description': name.capitalize() + ' Generation Max (Bytes)',
    })

# THREADS
main_stats['es_jvm_threads'] = merge(GAUGE, {
    'path': 'jvm.threads.count',
    'units': 'threads',
    'description': 'JVM Threads',
})

# GC
for name in ['young', 'old']:
    main_stats['es_' + name + '_gcs'] = merge(COUNTER, {
        'path': 'jvm.gc.collectors.' + name + '.collection_count',
        'units': 'collections/sec',
        'description': 'Collections/sec',
    })
    main_stats['es_' + name + '_gc_time'] = merge(TIME, {
        'path': 'jvm.gc.collectors.' + name + '.collection_time_in_millis',
        'description': 'Collection Time/sec'
    })

# BUFFER POOLS
for name in ['direct', 'mapped']:
    main_stats['es_jvm_' + name + '_buffer_pools'] = merge(GAUGE, {
        'path': 'jvm.buffer_pools.' + name + '.count',
        'units': 'pools',
        'description': 'Pools',
    })
    main_stats['es_jvm_' + name + '_buffer_pool_used'] = merge(BYTES_GAUGE, {
        'path': 'jvm.buffer_pools.' + name + '.used_in_bytes',
        'description': 'Pool Used Bytes',
    })
    main_stats['es_jvm_' + name + '_buffer_pool_total'] = merge(BYTES_GAUGE, {
        'path': 'jvm.buffer_pools.' + name + '.total_capacity_in_bytes',
        'description': 'Pool Total Capacity Bytes',
    })


# FILE SYSTEM METRICS #
main_stats['es_fs_reads'] = merge(COUNTER, {
    'path': 'fs.data.0.disk_reads',
    'units': 'reads/sec',
    'description': 'Reads/sec',
})
main_stats['es_fs_read_bytes'] = merge(BYTES, {
    'path': 'fs.data.0.disk_read_size_in_bytes',
    'description': 'Bytes Read/sec',
})
main_stats['es_fs_writes'] = merge(COUNTER, {
    'path': 'fs.data.0.disk_writes',
    'units': 'writes/sec',
    'description': 'Writes/sec',
})
main_stats['es_fs_write_bytes'] = merge(BYTES, {
    'path': 'fs.data.0.disk_write_size_in_bytes',
    'description': 'Bytes Written/sec',
})
main_stats['es_fs_disk_queue'] = merge(GAUGE, {
    'path': 'fs.data.0.disk_queue',
    'units': 'operations',
    'description': 'Disk Queue',
})
main_stats['es_fs_disk_service_time'] = merge(GAUGE, {
    'path': 'fs.data.0.disk_service_time',
    'units': 'millis',
    'description': 'Disk Service Time (millis)',
})

# HTTP METRICS #
main_stats['es_http_current_connections'] = merge(GAUGE, {
    'path': 'http.current_open',
    'units': 'connections',
    'description': 'Open Connections',
})
main_stats['es_http_connections'] = merge(COUNTER, {
    'path': 'http.total_opened',
    'units': 'connections/sec',
    'description': 'New Connections/sec',
})

# PROCESS METRICS #
main_stats['es_open_file_descriptors'] = merge(GAUGE, {
    'path': 'process.open_file_descriptors',
    'units': 'file descriptors',
    'description': 'Open File Descriptors',
})

# THREAD POOL METRICS #
for name in ['generic', 'index', 'get', 'snapshot', 'merge', 'suggest', 'bulk',
             'optimize', 'warmer', 'flush', 'search', 'percolate',
             'management', 'refresh']:
    main_stats['es_thread_pool_' + name + '_size'] = merge(GAUGE, {
        'path': 'thread_pool.' + name + '.threads',
        'units': 'threads',
        'description': 'Threads',
    })
    main_stats['es_thread_pool_' + name + '_queue'] = merge(GAUGE, {
        'path': 'thread_pool.' + name + '.queue',
        'units': 'operations',
        'description': 'Operations',
    })
    main_stats['es_thread_pool_' + name + '_active'] = merge(GAUGE, {
        'path': 'thread_pool.' + name + '.active',
        'units': 'operations',
        'description': 'Operations',
    })
    main_stats['es_thread_pool_' + name + '_rejected'] = merge(COUNTER, {
        'path': 'thread_pool.' + name + '.rejected',
        'units': 'operations/sec',
        'description': 'Operations/sec',
    })
    main_stats['es_thread_pool_' + name + '_completed'] = merge(COUNTER, {
        'path': 'thread_pool.' + name + '.completed',
        'units': 'operations/sec',
        'description': 'Operations/sec',
    })

# Search groups
search_group_stats = dict()
search_group_stats['es_%(group)s_queries'] = merge(COUNTER, {
    'path': 'indices.search.groups.%(group)s.query_total',
    'units': 'queries/sec',
    'description': 'Queries/sec',
})
search_group_stats['es_%(group)s_query_time'] = merge(TIME, {
    'path': 'indices.search.groups.%(group)s.query_time_in_millis',
    'description': 'Query Time/sec'
})
search_group_stats['es_%(group)s_fetches'] = merge(COUNTER, {
    'path': 'indices.search.groups.%(group)s.fetch_total',
    'units': 'fetches/sec',
    'description': 'Fetches/sec',
})
search_group_stats['es_%(group)s_fetch_time'] = merge(TIME, {
    'path': 'indices.search.groups.%(group)s.fetch_time_in_millis',
    'description': 'Fetch Time/sec'
})

# Health stats to be collected
health_stats = dict()
health_stats['es_nodes'] = merge(GAUGE, {
    'path': 'number_of_nodes',
    'units': 'nodes',
    'description': 'nodes online'
})
health_stats['es_data_nodes'] = merge(GAUGE, {
    'path': 'number_of_data_nodes',
    'units': 'nodes',
    'description': 'data nodes online'
})
health_stats['es_active_primary_shards'] = merge(GAUGE, {
    'path': 'active_primary_shards',
    'units': 'shards',
    'description': 'primary shards active'
})
health_stats['es_active_shards'] = merge(GAUGE, {
    'path': 'active_shards',
    'units': 'shards',
    'description': 'shards active'
})
health_stats['es_relocating_shards'] = merge(GAUGE, {
    'path': 'relocating_shards',
    'units': 'shards',
    'description': 'shards relocating'
})
health_stats['es_initializing_shards'] = merge(GAUGE, {
    'path': 'initializing_shards',
    'units': 'shards',
    'description': 'shards initializing'
})
health_stats['es_unassigned_shards'] = merge(GAUGE, {
    'path': 'unassigned_shards',
    'units': 'shards',
    'description': 'shards initializing'
})


class MetricCache(object):
    def __init__(self):
        self.queue = Queue()
        self.cache = {}

    def get(self, url):
        self.queue.put(url)
        data, last_fetch = self.cache.get(url, (None, 0))
        return data, last_fetch

    def set(self, url, data, last_fetch):
        self.cache[url] = (data, last_fetch)

    @staticmethod
    def url_fetcher(cache):
        while True:
            url = cache.queue.get()
            if url is None:
                break
            try:
                data = load(url)
                cache.set(url, data, time.time())
            except socket.timeout:
                continue
            except ValueError:
                continue


def dig_it_up(obj, path):
    def tryint(s):
        try:
            return int(s)
        except:
            return s
    try:
        if type(path) in (str, unicode):
            path = [tryint(s) for s in path.split('.')]
        return reduce(lambda x, y: x[y], path, obj)
    except:
        return False


def load(url, timeout=URLOPEN_TIMEOUT):
    return json.load(urllib2.urlopen(url, None, timeout))


def update_result(data, cache):
    # If time delta is > 3 seconds, then update the JSON results
    now = time.time()
    diff = now - data['last_update']
    if diff > 3:
        data['stats'], data['last_fetch'] = cache.get(data['url'])
        data['last_update'] = now


def get_stat(data, stats, cache, name):
    update_result(data, cache)

    if data['stats'] is None:
        return None

    # Don't keep returning stale data forever
    now = time.time()
    diff = now - data['last_fetch']
    if diff > LAST_FETCH_THRESHOLD:
        return None

    path = data['path_transformer'](data, stats[name]['path'])
    val = dig_it_up(data['stats'], path)

    # Check to make sure we have a valid result
    if not isinstance(val, bool):
        return float(val)
    else:
        return None


def deunicode(s):
    if isinstance(s, unicode):
        return s.encode('ascii', 'ignore')
    return s


def metric_init(params):
    metric_cache = MetricCache()

    # having ganglia callbacks block a long time makes gmond very sad and
    # elasticsearch can be slow at times, thus spawn a thread to fetch stats
    # asynchronously.
    fetch_thread = threading.Thread(target=MetricCache.url_fetcher,
                                    args=(metric_cache,))
    fetch_thread.daemon = True
    fetch_thread.start()

    descriptors = []

    host = params.get('host', 'http://localhost:9200/')
    metric_group = params.get('metric_group', 'elasticsearch')

    Desc_Skel = {
        'name': 'XXX',
        'time_max': 10,
        'value_type': 'double',
        'units': 'units',
        'format': '%.0f',
        'description': 'XXX',
        'groups': metric_group,
    }

    def init(stats):
        for stat_name, stat in stats.iteritems():
            d = merge(Desc_Skel, stat)
            d['name'] = stat_name
            descriptors.append(d)

    def main_path_transformer(data, path):
        node = data['stats']['nodes'].keys()[0]
        return 'nodes.%(node)s.%(path)s' % {'node': node, 'path': path}
    stat_groups = 'thread_pool,process,transport,fs,jvm,indices'
    main_url = '{0}/_nodes/_local/stats/{1}'.format(host, stat_groups)
    main_result = {
        'last_update': 0,
        'url': main_url,
        'path_transformer': main_path_transformer,
    }
    Desc_Skel['call_back'] = partial(get_stat, main_result, main_stats,
                                     metric_cache)
    init(main_stats)

    # Monitor search grouped stats by making a stat per group.
    stats_groups_results = {
        'last_update': 0,
        'url': main_url,
        'path_transformer': main_path_transformer,
    }
    main_data = load(main_url)
    node = main_data['nodes'].keys()[0]
    if 'groups' in main_data['nodes'][node]['indices']['search']:
        for group in main_data['nodes'][node]['indices']['search']['groups']:
            group_index_stats = dict()
            for stat_name, stat in search_group_stats.iteritems():
                stat_name = stat_name % {'group': group.replace(' ', '_')}
                stat_name = deunicode(stat_name)
                path = deunicode(stat['path'] % {'group': group})
                group_index_stats[stat_name] = merge(stat, {'path': path})
            Desc_Skel['call_back'] = partial(
                get_stat, stats_groups_results, group_index_stats,
                metric_cache)
            init(group_index_stats)

    # Cluster health stats and the last time we fetched them.
    def noop_path_transformer(data, path):
        return path
    health_result = {
        'last_update': 0,
        'url': '{0}_cluster/health'.format(host),
        'path_transformer': noop_path_transformer,
    }
    Desc_Skel['call_back'] = partial(get_stat, health_result, health_stats,
                                     metric_cache)
    init(health_stats)

    return descriptors


def metric_cleanup():
    pass


# This code is for debugging and unit testing
if __name__ == '__main__':
    descriptors = metric_init({})
    from time import sleep
    while True:
        for d in descriptors:
            v = d['call_back'](d['name'])
            print 'value for %s is %s' % (d['name'], str(v))
        sleep(10)
