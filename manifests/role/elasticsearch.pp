# = Class: role::elasticsearch::config
#
# This class sets up Elasticsearch configuration in a WMF-specific way.
#
class role::elasticsearch::config {
    # Config
    if ($::realm == 'labs') {
        $multicast_group = '224.2.2.4'
        $master_eligible = true
        if ($::hostname =~ /^deployment-/) {
            # Beta
            # Has four nodes all of which can be master
            $minimum_master_nodes = 3
            $cluster_name         = 'beta-search'
            $heap_memory          = '4G'
        } else {
            # Regular labs instance
            # We don't know how many instances will be in each labs project so
            # we got with the lowest common denominator assuming that you can
            # recover from a split brain on your own.  It'd be good practice
            # in case we have one in production.
            $minimum_master_nodes = 1
            # This should be configured per project
            if $::elasticsearch_cluster_name == undef {
                $message = 'must be set to something unique to the labs project'
                fail("\$::elasticsearch_cluster_name $message")
            }
            $cluster_name         = $::elasticsearch_cluster_name
            $heap_memory          = '2G'
        }
    } else {
        # Production
        $multicast_group = $::site ? {
            'eqiad' => '224.2.2.5',
            'pmtpa' => '224.2.2.6',
        }
        $master_eligible = $::hostname ? {
            /^elastic1001/        => true,  # Rack A3
            /^elastic1008/        => true,  # Rack C5
            # TODO Move this when we get machines on another row/rack
            /^elastic1012/        => true,  # Rack C5
            default               => false,
        }
        $minimum_master_nodes = 2
        $cluster_name         = "production-search-${::site}"
        $heap_memory          = '30G'
    }
}

# = Class: role::elasticsearch::server
#
# This class sets up Elasticsearch in a WMF-specific way.
#
class role::elasticsearch::server inherits role::elasticsearch::config {

    # Install
    class { '::elasticsearch':
        multicast_group      => $multicast_group,
        master_eligible      => $master_eligible,
        minimum_master_nodes => $minimum_master_nodes,
        cluster_name         => $cluster_name,
        heap_memory          => $heap_memory,
        plugins_dir          => '/srv/deployment/elasticsearch/plugins',
    }
    deployment::target { 'elasticsearchplugins': }

    include ::elasticsearch::ganglia
    include ::elasticsearch::log::hot_threads
    include ::elasticsearch::nagios::check
}
