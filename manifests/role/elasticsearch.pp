# = Class: role::elasticsearch::config
#
# This class sets up Elasticsearch configuration in a WMF-specific way.
#

@monitor_group { 'elasticsearch_pmtpa': description => 'pmtpa elasticsearch servers' }
@monitor_group { 'elasticsearch_eqiad': description => 'eqiad elasticsearch servers' }
@monitor_group { 'elasticsearch_codfw': description => 'codfw elasticsearch servers' }
@monitor_group { 'elasticsearch_esams': description => 'esams elasticsearch servers' }
@monitor_group { 'elasticsearch_ulsfo': description => 'ulsfo elasticsearch servers' }

class role::elasticsearch::config {
    # Config
    if ($::realm == 'labs') {
        $multicast_group            = '224.2.2.4'
        $master_eligible            = true
        $recover_after_time         = '1m'
        $awareness_attributes       = undef
        $row                        = undef
        $rack                       = undef
        $plugins_mandatory          = undef
        $filter_cache_size          = '10%'
        $bulk_thread_pool_capacity  = undef
        $bulk_thread_pool_executors = undef
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
            $unicast_hosts        = ['deployment-elastic01',
                'deployment-elastic02', 'deployment-elastic03',
                'deployment-elastic04']
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
            'elastic1002' => true,
            'elastic1007' => true,
            'elastic1014' => true,
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
            /^elastic101[3-9]/          => 'D3',
            default                     => fail("Don't know rack for $::host"),
        }
        $row                  = regsubst($rack, '^(.).$', '\1' )
        # We're not turning on awareness_attributes right yet.  We'll do that
        # with the setting update API after things settle down with the 1.0
        # release then we'll update puppet.
        $awareness_attributes = 'row'
        $unicast_hosts        = undef

        # Production elasticsearch needs these plugins to be loaded in order
        # to work properly.  This will keep elasticsearch from starting
        # if these plugins are  not available.
        $plugins_mandatory    = ['experimental highlighter', 'analysis-icu']

        # Production can get a lot of use out of the filter cache.
        $filter_cache_size          = '20%'
        $bulk_thread_pool_capacity  = 1000
        $bulk_thread_pool_executors = 6
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

    deployment::target { 'elasticsearchplugins': }

    # Install
    class { '::elasticsearch':
        multicast_group            => $multicast_group,
        master_eligible            => $master_eligible,
        minimum_master_nodes       => $minimum_master_nodes,
        cluster_name               => $cluster_name,
        heap_memory                => $heap_memory,
        plugins_dir                => '/srv/deployment/elasticsearch/plugins',
        plugins_mandatory          => $plugins_mandatory,
        expected_nodes             => $expected_nodes,
        recover_after_nodes        => $recover_after_nodes,
        recover_after_time         => $recover_after_time,
        awareness_attributes       => $awareness_attributes,
        row                        => $row,
        rack                       => $rack,
        unicast_hosts              => $unicast_hosts,
        # This depends on the elasticsearchplugins deployment.
        # A new elasticsearch server shouldn't join the cluster until
        # the plugins are properly deployed in place.  Note that this
        # means you will likely have to run puppet twice in order to
        # get elasticsearch up and running.  Once for the initial
        # node configuration (including salt), and then once again
        # after you have signed this node's new salt key over on the salt master.
        require                    => Deployment::Target['elasticsearchplugins'],
        bulk_thread_pool_capacity  => $bulk_thread_pool_capacity,
        bulk_thread_pool_executors => $bulk_thread_pool_executors,
    }

    include ::elasticsearch::ganglia
    include ::elasticsearch::log::hot_threads
    include ::elasticsearch::nagios::check

    # jq is really useful, especially for parsing
    # elasticsearch REST command JSON output.
    package { 'jq':
        ensure => 'installed',
    }
}
