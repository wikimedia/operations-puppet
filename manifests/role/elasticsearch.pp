# = Class: role::elasticsearch
#
# This class manages an elasticsearch service in a WMF-specific way
#
# == Parameters:
# - $::elasticsearch_cluster_name:  Name of the elasticsearch cluster.  Try to
#       pick something unique because clusers are joined via multicast.
# - $::elasticsearch_heap_memory:   amount of memory to allocate to
#       elasticsearch.  Defaults to "2G".  Should be set to about half of ram or
#       a 30G, whichever is smaller.
#
class role::elasticsearch () {
    if $::elasticsearch_cluster_name == undef {
        fail("$::elasticsearch_cluster_name must be set to something unique for your cluster")
    }
    class { "::elasticsearch":
        cluster_name => $::elasticsearch_cluster_name,
        heap_memory => $::elasticsearch_heap_memory ? {
            undef => "2G",
            default => $::elasticsearch_heap_memory,
        }
    }
}
