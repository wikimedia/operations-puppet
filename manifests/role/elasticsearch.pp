# = Class: role::elasticsearch::production
#
# This class manages an elasticsearch service in a WMF-specific way for
# production.
#
class role::elasticsearch::production {
    class { '::elasticsearch':
        cluster_name => 'production-search',
        heap_memory  => '30G',
    }
}

# = Class: role::elasticsearch::beta
#
# This class manages an elasticsearch service in a WMF-specific way for beta.
#
class role::elasticsearch::beta {
    class { '::elasticsearch':
        cluster_name => 'beta-search',
    }
}

# = Class: role::elasticsearch::labs
#
# This class manages an elasticsearch service in a WMF-specific way for labs.
# Note that this requires the elasticsearch_cluster_name global to be set.
#
class role::elasticsearch::labs {
    if $::elasticsearch_cluster_name == undef {
        fail("$::elasticsearch_cluster_name must be set to something unique " +
            'for your cluster')
    }
    class { '::elasticsearch':
        cluster_name => $::elasticsearch_cluster_name,
    }
}
