# = Class: role::elasticsearch::config
#
# This class sets up Elasticsearch configuration in a WMF-specific way.
#
class role::elasticsearch::config {
    # Config
    if ($::realm == 'labs') {
        $multicast_group    = '224.2.2.4'
        $master_eligible    = true
        $recover_after_time = '1m'
        if ($::hostname =~ /^deployment-/) {
            # Beta
            # Has four nodes all of which can be master
            $minimum_master_nodes = 3
            $cluster_name         = 'beta-search'
            $heap_memory          = '4G'
            $expected_nodes       = 4
            # The cluster can limp along just fine with three nodes so we'll
            # let it
            $recover_after_nodes  = 3
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
            # Leave recovery settings and let labs users deal with inefficient
            # full cluster restarts rather than make them configure more stuff
            $expected_nodes       = 1
            $recover_after_nodes  = 1
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
        $expected_nodes       = 12
        # We're pretty tight on space on the cluster right now so we really
        # can't get away with running without almost all the nodes.
        $recover_after_nodes  = 10
        # We really do want all the nodes to come back properly so lets give
        # them quite a bit of time.
        $recover_after_time   = '20m'
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
        expected_nodes       => $expected_nodes,
        recover_after_nodes  => $recover_after_nodes,
        recover_after_time   => $recover_after_time,
    }
    deployment::target { 'elasticsearchplugins': }

    include ::elasticsearch::ganglia
    include ::elasticsearch::log::hot_threads
    include ::elasticsearch::nagios::check
}
