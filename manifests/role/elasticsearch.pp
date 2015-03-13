# = Class: role::elasticsearch::server
#
# This class sets up Elasticsearch in a WMF-specific way.
#

@monitoring::group { 'elasticsearch_eqiad': description => 'eqiad elasticsearch servers' }
@monitoring::group { 'elasticsearch_codfw': description => 'codfw elasticsearch servers' }
@monitoring::group { 'elasticsearch_esams': description => 'esams elasticsearch servers' }
@monitoring::group { 'elasticsearch_ulsfo': description => 'ulsfo elasticsearch servers' }

class role::elasticsearch::server($cluster_name = 'elasticsearch',
        $multicast_group = '224.2.2.4',
        $master_eligible = true,
        $minimum_master_nodes = 1,
        $expected_nodes = 1,
        $recover_after_time = '1m',
        $recover_after_nodes = 1,
        $awareness_attributes = undef,
        $plugins_mandatory = undef,
        $filter_cache_size = '10%',
        $bulk_thread_pool_capacity = undef,
        $bulk_thread_pool_executors = undef,
        $statsd_host = undef,
        $unicast_hosts = undef,
        $heap_memory = '2G',
        $row = undef,
        $rack = undef) {

    if ($::realm == 'production') {
        include standard
        include admin

        $rack = $::hostname ? {
            /^elastic100[0-6]/          => 'A3',
            /^elastic10(0[7-9]|1[0-2])/ => 'C5',
            /^elastic101[3-9]/          => 'D3',
            /^elastic10(1[3-9]|2[0-2])/ => 'D3',
            /^elastic10(2[3-9]|3[01])/  => 'D4',
            default                     => 'Unknown',
        }
        if ($rack == 'Unknown') {
            fail("Don't know rack for $::host")
        }
        $row = regsubst($rack, '^(.).$', '\1' )
    }

    if hiera('has_lvs', true) {
        include lvs::realserver
    }

    system::role { 'role::elasticsearch::server':
        ensure      => 'present',
        description => 'elasticsearch server',
    }

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }

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
        require                    => Package['elasticsearch/plugins'],
        bulk_thread_pool_capacity  => $bulk_thread_pool_capacity,
        bulk_thread_pool_executors => $bulk_thread_pool_executors,
        statsd_host                => $statsd_host,
        auto_create_index          => '+apifeatureusage-*,-*',
        merge_threads              => 1,
    }

    if hiera('has_ganglia', true) {
        include ::elasticsearch::ganglia
    }

    include ::elasticsearch::log::hot_threads
    include ::elasticsearch::nagios::check
}
