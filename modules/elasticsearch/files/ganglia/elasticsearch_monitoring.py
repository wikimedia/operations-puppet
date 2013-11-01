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

import time
import urllib2
from functools import partial


# Used to merge stat descriptions
def merge(skel, stat):
    d = skel.copy()
    d.update(stat)
    return d

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
stats = dict()
## CACHE
stats['es_filter_cache_size'] = merge(BYTES_GAUGE, {
    'path': 'indices.filter_cache.memory_size_in_bytes',
    'description': 'Filter Cache Size'
})
stats['es_filter_cache_evictions'] = merge(COUNTER, {
    'path': 'indices.filter_cache.evictions',
    'description': 'Filter Cache Evictions/sec',
})
stats['es_id_cache_size'] = merge(BYTES_GAUGE, {
    'path': 'indices.id_cache.memory_size_in_bytes',
    'description': 'Id Cache Size',
})
stats['es_fielddata_cache_size'] = merge(BYTES_GAUGE, {
    'path': 'indices.fielddata.memory_size_in_bytes',
    'description': 'Field Data Cache Size'
})
stats['es_fielddata_cache_evictions'] = merge(COUNTER, {
    'path': 'indices.fielddata.evictions',
    'units': 'evictions/sec',
    'description': 'Field Data Cache Evictions/sec',
})

## DOCS
stats['es_docs_count'] = merge(GAUGE, {
    'path': 'indices.docs.count',
    'units': 'docs',
    'description': 'Documents',
})
stats['es_docs_deleted'] = merge(GAUGE, {
    'path': 'indices.docs.deleted',
    'units': 'docs',
    'description': 'Deleted Documents',
})

## FLUSH
stats['es_flushes'] = merge(COUNTER, {
    'path': 'indices.flush.total',
    'units': 'flushes',
    'description': 'Flushes/sec',
})
stats['es_flush_time'] = merge(TIME, {
    'path': 'indices.flush.total_time_in_millis',
    'description': 'Flush Time/sec'
})

## GET
stats['es_gets'] = merge(COUNTER, {
    'path': 'indices.get.total',
    'units': 'gets/sec',
    'description': 'Gets/sec',
})
stats['es_get_time'] = merge(TIME, {
    'path': 'indices.get.time_in_millis',
    'description': 'Get Time/sec'
})
stats['es_gets_exists'] = merge(COUNTER, {
    'path': 'indices.get.exists_total',
    'units': 'get/sec',
    'description': 'Get (exists)/sec',
})
stats['es_get_exists_time'] = merge(TIME, {
    'path': 'indices.get.exists_time_in_millis',
    'description': 'Get (exists) Time/sec'
})
stats['es_gets_missing'] = merge(COUNTER, {
    'path': 'indices.get.missing_total',
    'units': 'get/sec',
    'description': 'Gets (missing)/sec',
})
stats['es_get_missing_time'] = merge(TIME, {
    'path': 'indices.get.missing_time_in_millis',
    'description': 'Gets (missing) Time/sec'
})

## INDEXING
stats['es_deletes'] = merge(COUNTER, {
    'path': 'indices.indexing.delete_total',
    'units': 'deletes/sec',
    'description': 'Deletes/sec',
})
stats['es_delete_time'] = merge(TIME, {
    'path': 'indices.indexing.delete_time_in_millis',
    'description': 'Delete Time/sec'
})
stats['es_indexes'] = merge(COUNTER, {
    'path': 'indices.indexing.index_total',
    'units': 'indexes/sec',
    'description': 'Indexes Requests/sec',
})
stats['es_index_time'] = merge(TIME, {
    'path': 'indices.indexing.index_time_in_millis',
    'description': 'Index Time/sec'
})

## MERGES
stats['es_merges'] = merge(COUNTER, {
    'path': 'indices.merges.total',
    'units': 'merges/sec',
    'description': 'Merges/sec',
})
stats['es_merge_time'] = merge(TIME, {
    'path': 'indices.merges.total_time_in_millis',
    'description': 'Merge Time/sec'
})
stats['es_merge_data'] = merge(BYTES, {
    'path': 'indices.merges.total_size_in_bytes',
    'description': 'Bytes/sec'
})

## REFRESH
stats['es_refreshes'] = merge(COUNTER, {
    'path': 'indices.refresh.total',
    'units': 'refreshes/sec',
    'description': 'Refreshes/sec',
})
stats['es_refresh_time'] = merge(TIME, {
    'path': 'indices.refresh.total_time_in_millis',
    'description': 'Refresh Time/sec'
})

## WARMER
stats['es_warmers'] = merge(COUNTER, {
    'path': 'indices.warmer.total',
    'units': 'warmers/sec',
    'description': 'Warmers/sec',
})
stats['es_warmer_time'] = merge(TIME, {
    'path': 'indices.warmer.total_time_in_millis',
    'description': 'Warmer Time/sec'
})

## SEARCH
stats['es_queries'] = merge(COUNTER, {
    'path': 'indices.search.query_total',
    'units': 'queries/sec',
    'description': 'Queries/sec',
})
stats['es_query_time'] = merge(TIME, {
    'path': 'indices.search.query_time_in_millis',
    'description': 'Query Time/sec'
})
stats['es_fetches'] = merge(COUNTER, {
    'path': 'indices.search.fetch_total',
    'units': 'fetches/sec',
    'description': 'Fetches/sec',
})
stats['es_fetch_time'] = merge(TIME, {
    'path': 'indices.search.fetch_time_in_millis',
    'description': 'Fetch Time/sec'
})

## STORE
stats['es_indices_size'] = merge(BYTES_GAUGE, {
    'path': 'indices.store.size_in_bytes',
    'description': 'Indices Size'
})
stats['es_indices_throttle_time'] = merge(TIME, {
    'path': 'indices.store.throttle_time_in_millis',
    'description': 'Throttle Time/sec'
})

# JVM METRICS #
## MEM
stats['es_heap_committed'] = merge(BYTES_GAUGE, {
    'path': 'jvm.mem.heap_committed_in_bytes',
    'description': 'Java Heap Committed (Bytes)',
})
stats['es_heap_used'] = merge(BYTES_GAUGE, {
    'path': 'jvm.mem.heap_used_in_bytes',
    'description': 'Java Heap Used (Bytes)',
})
stats['es_non_heap_committed'] = merge(BYTES_GAUGE, {
    'path': 'jvm.mem.non_heap_committed_in_bytes',
    'description': 'Java Non Heap Committed (Bytes)',
})
stats['es_non_heap_used'] = merge(BYTES_GAUGE, {
    'path': 'jvm.mem.non_heap_used_in_bytes',
    'description': 'Java Non Heap Used (Bytes)',
})

## THREADS
stats['es_jvm_threads'] = merge(GAUGE, {
    'path': 'jvm.threads.count',
    'units': 'threads',
    'description': 'JVM Threads',
})

## GC
for name, path in [('par_new', 'ParNew'),
                   ('concurrent_mark_sweep', 'ConcurrentMarkSweep')]:
    stats['es_' + name + '_gcs'] = merge(COUNTER, {
        'path': 'jvm.gc.collectors.' + path + '.collection_count',
        'units': 'collections/sec',
        'description': 'Collections/sec',
    })
    stats['es_' + name + '_gc_time'] = merge(TIME, {
        'path': 'jvm.gc.collectors.' + path + '.collection_time_in_millis',
        'description': 'Collection Time/sec'
    })


## Buffer Pools
for name in ['direct', 'mapped']:
    stats['es_jvm_' + name + '_buffer_pools'] = merge(GAUGE, {
        'path': 'jvm.buffer_pools.' + name + '.count',
        'units': 'pools',
        'description': 'Pools',
    })
    stats['es_jvm_' + name + '_buffer_pool_used'] = merge(BYTES_GAUGE, {
        'path': 'jvm.buffer_pools.' + name + '.used_in_bytes',
        'description': 'Pool Used Bytes',
    })
    stats['es_jvm_' + name + '_buffer_pool_total'] = merge(BYTES_GAUGE, {
        'path': 'jvm.buffer_pools.' + name + '.total_capacity_in_bytes',
        'description': 'Pool Total Capacity Bytes',
    })


# FILE SYSTEM METRICS #
stats['es_fs_reads'] = merge(COUNTER, {
    'path': 'fs.data.0.disk_reads',
    'units': 'reads/sec',
    'description': 'Reads/sec',
})
stats['es_fs_read_bytes'] = merge(BYTES, {
    'path': 'fs.data.0.disk_read_size_in_bytes',
    'description': 'Bytes Read/sec',
})
stats['es_fs_writes'] = merge(COUNTER, {
    'path': 'fs.data.0.disk_writes',
    'units': 'writes/sec',
    'description': 'Writes/sec',
})
stats['es_fs_write_bytes'] = merge(BYTES, {
    'path': 'fs.data.0.disk_write_size_in_bytes',
    'description': 'Bytes Written/sec',
})
stats['es_fs_disk_queue'] = merge(GAUGE, {
    'path': 'fs.data.0.disk_queue',
    'units': 'operations',
    'description': 'Disk Queue',
})
stats['es_fs_disk_service_time'] = merge(GAUGE, {
    'path': 'fs.data.0.disk_service_time',
    'units': 'millis',
    'description': 'Disk Service Time (millis)',
})

# HTTP METRICS #
stats['es_http_current_connections'] = merge(GAUGE, {
    'path': 'http.current_open',
    'units': 'connections',
    'description': 'Open Connections',
})
stats['es_http_connections'] = merge(COUNTER, {
    'path': 'http.total_opened',
    'units': 'connections/sec',
    'description': 'New Connections/sec',
})

# PROCESS METRICS #
stats['es_open_file_descriptors'] = merge(GAUGE, {
    'path': 'process.open_file_descriptors',
    'units': 'file descriptors',
    'description': 'Open File Descriptors',
})

# THREAD POOL METRICS #
for name in ['generic', 'index', 'get', 'snapshot', 'merge', 'suggest', 'bulk',
             'optimize', 'warmer', 'flush', 'search', 'percolate',
             'management', 'refresh']:
    stats['es_thread_pool_' + name + '_size'] = merge(GAUGE, {
        'path': 'thread_pool.' + name + '.threads',
        'units': 'threads',
        'description': 'Threads',
    })
    stats['es_thread_pool_' + name + '_queue'] = merge(GAUGE, {
        'path': 'thread_pool.' + name + '.queue',
        'units': 'operations',
        'description': 'Operations',
    })
    stats['es_thread_pool_' + name + '_active'] = merge(GAUGE, {
        'path': 'thread_pool.' + name + '.active',
        'units': 'operations',
        'description': 'Operations',
    })
    stats['es_thread_pool_' + name + '_rejected'] = merge(COUNTER, {
        'path': 'thread_pool.' + name + '.rejected',
        'units': 'operations/sec',
        'description': 'Operations/sec',
    })
    stats['es_thread_pool_' + name + '_completed'] = merge(COUNTER, {
        'path': 'thread_pool.' + name + '.completed',
        'units': 'operations/sec',
        'description': 'Operations/sec',
    })


# Global holding the last time we fetched data from ES.  We only fetch it every
# 3 seconds.
mainResult = dict()
mainResult['last_update'] = 0


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


def update_result(result, url):
    # If time delta is > 3 seconds, then update the JSON results
    now = time.time()
    diff = now - result['last_update']
    if diff > 3:
        result['stats'] = json.load(urllib2.urlopen(url, None, 2))
        result['last_update'] = now
    return result


def getStat(url, name):
    update_result(mainResult, url)

    node = mainResult['stats']['nodes'].keys()[0]
    val = dig_it_up(mainResult['stats'],
                    'nodes.%s.%s' % (node, stats[name]['path']))

    # Check to make sure we have a valid result
    if not isinstance(val, bool):
        return float(val)
    else:
        return None


def metric_init(params):
    descriptors = []

    host = params.get('host', 'http://localhost:9200/')
    url_cluster = '{0}_cluster/nodes/_local/stats?all=true'.format(host)
    metric_group = params.get('metric_group', 'elasticsearch')

    Desc_Skel = {
        'name': 'XXX',
        'call_back': partial(getStat, url_cluster),
        'time_max': 10,
        'value_type': 'double',
        'units': 'units',
        'format': '%.0f',
        'description': 'XXX',
        'groups': metric_group,
    }
    for stat_name, stat in stats.iteritems():
        d = merge(Desc_Skel, stat)
        d['name'] = stat_name
        descriptors.append(d)
    return descriptors


def metric_cleanup():
    pass


#This code is for debugging and unit testing
if __name__ == '__main__':
    descriptors = metric_init({})
    for d in descriptors:
        v = d['call_back'](d['name'])
        print 'value for %s is %s' % (d['name'], str(v))
