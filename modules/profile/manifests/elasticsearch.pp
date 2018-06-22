#
# This class configures elasticsearch
#
# == Parameters:
#
# For documentation of parameters, see the elasticsearch class.
#
class profile::elasticsearch(
    $cluster_name = hiera('profile::elasticsearch::cluster_name'),
    $cluster_hosts = hiera('profile::elasticsearch::cluster_hosts'),
    $unicast_hosts = hiera('profile::elasticsearch::unicast_hosts'),
    $base_data_dir = hiera('profile::elasticsearch::base_data_dir'),
    $holds_data = hiera('profile::elasticsearch::holds_data', true),
    $plugins_mandatory = hiera('profile::elasticsearch::plugins_mandatory', undef),
    $minimum_master_nodes = hiera('profile::elasticsearch::minimum_master_nodes'),
    $heap_memory = hiera('profile::elasticsearch::heap_memory'),
    $expected_nodes = hiera('profile::elasticsearch::expected_nodes'),
    $logstash_host = hiera('logstash_host'),
    $logstash_port = hiera('logstash_gelf_port'),
    $send_logs_to_logstash = hiera('profile::elasticsearch::send_logs_to_logstash', true),
    $rack = hiera('profile::elasticsearch::rack'),
    $row = hiera('profile::elasticsearch::row'),
    $awareness_attributes = hiera('profile::elasticsearch::awareness_attributes'),
    $bulk_thread_pool_executors = hiera('profile::elasticsearch::bulk_thread_pool_executors', undef),
    $bulk_thread_pool_capacity = hiera('profile::elasticsearch::bulk_thread_pool_capacity', undef),
    $search_thread_pool_executors = hiera('profile::elasticsearch::search_thread_pool_executors', undef),
    $recover_after_time = hiera('profile::elasticsearch::recover_after_time', '1s'),
    $recover_after_nodes = hiera('profile::elasticsearch::recover_after_nodes', 1),
    $search_shard_count_limit = hiera('profile::elasticsearch::search_shard_count_limit', 1000),
    $reindex_remote_whitelist = hiera('profile::elasticsearch::reindex_remote_whitelist', ''),
    $ltr_cache_size = hiera('profile::elasticsearch::ltr_cache_size', undef),
    $http_port = hiera('profile::elasticsearch::http_port'),
    $transport_tcp_port = hiera('profile::elasticsearch::transport_tcp_port'),
    $auto_create_index = hiera('profile::elasticsearch::auto_create_index'),
    $filter_cache_size = hiera('profile::elasticsearch::filter_cache_size', undef),
    $script_max_compilations_per_minute = hiera('profile::elasticsearch::script_max_compilations_per_minute', undef),
    $curator_uses_unicast_hosts = hiera('profile::elasticsearch::curator_uses_unicast_hosts', true),
) {
    $master_eligible = $::fqdn in $unicast_hosts

    $elastic_nodes_ferm = join($cluster_hosts, ' ')

    ferm::service { 'elastic-inter-node':
        proto   => 'tcp',
        port    => $transport_tcp_port,
        notrack => true,
        srange  => "@resolve((${elastic_nodes_ferm}))",
    }

    apt::repository { 'wikimedia-elastic':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'component/elastic55 thirdparty/elastic55',
        before     => Class['::elasticsearch'],
    }

    # ensure that apt is refreshed before installing elasticsearch
    Exec['apt-get update'] -> Class['::elasticsearch']

    # Install
    class { '::elasticsearch':
        version                            => 5,
        plugins_mandatory                  => $plugins_mandatory,
        auto_create_index                  => $auto_create_index,
        base_data_dir                      => $base_data_dir,
        holds_data                         => $holds_data,
        # Production can get a lot of use out of the filter cache.
        filter_cache_size                  => $filter_cache_size,
        bulk_thread_pool_executors         => $bulk_thread_pool_executors,
        bulk_thread_pool_capacity          => $bulk_thread_pool_capacity,
        search_thread_pool_executors       => $search_thread_pool_executors,
        rack                               => $rack,
        row                                => $row,
        awareness_attributes               => $awareness_attributes,
        cluster_name                       => $cluster_name,
        unicast_hosts                      => $unicast_hosts,
        minimum_master_nodes               => $minimum_master_nodes,
        recover_after_time                 => $recover_after_time,
        recover_after_nodes                => $recover_after_nodes,
        heap_memory                        => $heap_memory,
        expected_nodes                     => $expected_nodes,
        master_eligible                    => $master_eligible,
        send_logs_to_logstash              => $send_logs_to_logstash,
        logstash_host                      => $logstash_host,
        logstash_gelf_port                 => $logstash_port,
        search_shard_count_limit           => $search_shard_count_limit,
        reindex_remote_whitelist           => $reindex_remote_whitelist,
        script_max_compilations_per_minute => $script_max_compilations_per_minute,
        ltr_cache_size                     => $ltr_cache_size,
        http_port                          => $http_port,
        transport_tcp_port                 => $transport_tcp_port,
        curator_uses_unicast_hosts         => $curator_uses_unicast_hosts,
    }
}
