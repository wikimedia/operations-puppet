# = Class: role::elasticsearch::production
#
# == Parameters:
# - $minimum_master_nodes:  how many master nodes must be online for this node
#       to believe that the Elasticsearch cluster is functioning correctly.
#       Defaults to 1.  Should be set to number of masster eligible nodes in
#       cluster / 2 + 1.
# - $master_eligible:  is this node eligible to be a master node?  Defaults to
#       true.
#
# This class manages an elasticsearch service in a WMF-specific way for
# production.
#
class role::elasticsearch::production {
    $multicast_group = $::site ? {
        'eqiad' => '224.2.2.5',
        'pmtpa' => '224.2.2.6',
    }
    class { '::elasticsearch':
        cluster_name         => "production-search-${::site}",
        heap_memory          => '7G',
        multicast_group      => $multicast_group,
        plugins_dir          => '/srv/deployment/elasticsearch/plugins',
        minimum_master_nodes => $minimum_master_nodes,
        master_eligible      => $master_eligible,
    }
    deployment::target { 'elasticsearchplugins': }

    include elasticsearch::ganglia
    include elasticsearch::nagios::check
}

# = Class: role::elasticsearch::beta
#
# This class manages an elasticsearch service in a WMF-specific way for beta.
#
class role::elasticsearch::beta {
    class { '::elasticsearch':
        cluster_name         => 'beta-search',
        heap_memory          => '4G',
        plugins_dir          => '/srv/deployment/elasticsearch/plugins',
        minimum_master_nodes => 3, # Has four nodes all of which can be master
    }
    deployment::target { 'elasticsearchplugins': }

    include elasticsearch::ganglia
    include elasticsearch::nagios::check
}

# = Class: role::elasticsearch::labs
#
# This class manages an elasticsearch service in a WMF-specific way for labs.
# Note that this requires the elasticsearch_cluster_name global to be set.
#
class role::elasticsearch::labs {
    if $::elasticsearch_cluster_name == undef {
        fail("$::elasticsearch_cluster_name must be set to something unique for your cluster")
    }
    class { '::elasticsearch':
        cluster_name => $::elasticsearch_cluster_name,
        plugins_dir  => '/srv/deployment/elasticsearch/plugins',
    }
    deployment::target { 'elasticsearchplugins': }

    include elasticsearch::ganglia
    include elasticsearch::nagios::check
}
