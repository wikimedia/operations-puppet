# = Class: role::elasticsearch::config
#
# This class sets up Elasticsearch configuration in a WMF-specific way.
#
class role::elasticsearch::config {
    # Config
    if ($::realm == 'labs') {
        $multicast_group      = '224.2.2.4'
        $master_eligible      = true
        $recover_after_time   = '1m'
        $awareness_attributes = undef
        $row                  = undef
        $rack                 = undef
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
            $unicast_hosts        = ['deployment-es01', 'deployment-es02',
                'deployment-es03', 'deployment-es04']
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
            # This can be configured per project
            $unicast_hosts        = $::elasticsearch_unicast_hosts

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
            'elastic1001' => true,
            'elastic1008' => true,
            'elastic1013' => true,
            default       => false,
        }
        $minimum_master_nodes = 2
        $cluster_name         = "production-search-${::site}"
        $heap_memory          = '30G'
        $expected_nodes       = 16
        # We should be able to run "OK" with 10 servers.
        $recover_after_nodes  = 10
        # But it'd save time if we just waited for all of them to come back so
        # lets give them plenty of time to restart.
        $recover_after_time   = '20m'
        $rack = $::hostname ? {
            /^elastic100[0-6]/          => 'A3',
            /^elastic10(0[7-9]|1[0-2])/ => 'C5',
            /^elastic101[3-6]/          => 'D3',
            default                     => fail("Don't know rack for $::host"),
        }
        $row                  = regsubst($rack, '^(.).$', '\1' )
        # We're not turning on awareness_attributes right yet.  We'll do that
        # with the setting update API after things settle down with the 1.0
        # release then we'll update puppet.
        $awareness_attributes = undef
        $unicast_hosts        = undef
    }
}

# = Class: role::elasticsearch::server
#
# This class sets up Elasticsearch in a WMF-specific way.
#
class role::elasticsearch::server inherits role::elasticsearch::config {

    system::role { 'role::elasticsearch::server':
        ensure      => 'present',
        description => 'elasticsearch server',
    }

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
        awareness_attributes => $awareness_attributes,
        row                  => $row,
        rack                 => $rack,
        unicast_hosts        => $unicast_hosts
    }
    deployment::target { 'elasticsearchplugins': }

    include ::elasticsearch::ganglia
    include ::elasticsearch::log::hot_threads
    include ::elasticsearch::nagios::check

    # jq is really useful, especially for parsing
    # elasticsearch REST command JSON output.
    package { 'jq':
        ensure => 'installed',
    }
}
