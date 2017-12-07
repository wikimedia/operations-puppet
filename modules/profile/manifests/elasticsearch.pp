#
# This class configures elasticsearch
#
# == Parameters:
# [*ferm_srange*]
#   The network range that should be allowed access to elasticsearch. This
#   needs to be customized for elasticsearch clusters serving non production
#   traffic. The relforge cluster is an example.
#   Default: $DOMAIN_NETWORKS
# [*storage_device*]
#   The name of the block device used to storage elasticsearch data.
#
# For documentation of other parameters, see the elasticsearch class.
#
class profile::elasticsearch(
    $cluster_name = hiera('profile::elasticsearch::cluster_name'),
    $ferm_srange = hiera('profile::elasticsearch::ferm_srange'),
    $cluster_hosts = hiera('profile::elasticsearch::cluster_hosts'),
    $unicast_hosts = hiera('profile::elasticsearch::unicast_hosts'),
    $minimum_master_nodes = hiera('profile::elasticsearch::minimum_master_nodes'),
    $heap_memory = hiera('profile::elasticsearch::heap_memory'),
    $expected_nodes = hiera('profile::elasticsearch::expected_nodes'),
    $graylog_hosts = hiera('logstash_host'),
    $graylog_port = hiera('logstash_gelf_port'),
    $rack = hiera('profile::elasticsearch::rack'),
    $row = hiera('profile::elasticsearch::row'),
    $awareness_attributes = hiera('profile::elasticsearch::awareness_attributes'),
    $bulk_thread_pool_executors = hiera('profile::elasticsearch::bulk_thread_pool_executors', 6),
    $search_thread_pool_executors = hiera('profile::elasticsearch::search_thread_pool_executors'),
    $certificate_name = hiera('profile::elasticsearch::certificate_name', $::fqdn),
    $recover_after_time = hiera('profile::elasticsearch::recover_after_time', '1s'),
    $recover_after_nodes = hiera('profile::elasticsearch::recover_after_nodes', 1),
    $search_shard_count_limit = hiera('profile::elasticsearch::search_shard_count_limit'),
    $reindex_remote_whitelist = hiera('profile::elasticsearch::reindex_remote_whitelist'),
    $storage_device = hiera('profile::elasticsearch::storage_device'),
) {
    $master_eligible = $::fqdn in $unicast_hosts

    ferm::service { 'elastic-http':
        proto   => 'tcp',
        port    => '9200',
        notrack => true,
        srange  => $ferm_srange,
    }

    $elastic_nodes_ferm = join($cluster_hosts, ' ')

    ferm::service { 'elastic-inter-node':
        proto   => 'tcp',
        port    => '9300',
        notrack => true,
        srange  => "@resolve((${elastic_nodes_ferm}))",
    }

    package {'wmf-elasticsearch-search-plugins':
        ensure => present,
        before => Service['elasticsearch'],
    }

    file { '/etc/udev/rules.d/elasticsearch-readahead.rules':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "SUBSYSTEM==\"block\", KERNEL==\"${storage_device}\", ACTION==\"add|change\", ATTR{bdi/read_ahead_kb}=\"128\"",
        notify  => Exec['elasticsearch_udev_reload'],
    }

    exec { 'elasticsearch_udev_reload':
        command     => '/sbin/udevadm control --reload && /sbin/udevadm trigger',
        refreshonly => true,
    }

    apt::repository { 'wikimedia-elastic':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'component/elastic55 thirdparty/elastic55',
        before     => Class['::elasticsearch'],
    }

    # Install
    class { '::elasticsearch':
        # Production elasticsearch needs these plugins to be loaded in order
        # to work properly.  This will keep elasticsearch from starting
        # if these plugins are  not available.
        plugins_mandatory                  => [
            'experimental-highlighter',
            'extra',
            'analysis-icu',
        ],
        # Let apifeatureusage create their indices
        auto_create_index                  => '+apifeatureusage-*,-*',
        # Production can get a lot of use out of the filter cache.
        filter_cache_size                  => '20%',
        bulk_thread_pool_executors         => $bulk_thread_pool_executors,
        bulk_thread_pool_capacity          => 1000,
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
        graylog_hosts                      => [ $graylog_hosts ],
        graylog_port                       => $graylog_port,
        version                            => 5,
        search_shard_count_limit           => $search_shard_count_limit,
        reindex_remote_whitelist           => $reindex_remote_whitelist,
        script_max_compilations_per_minute => 10000,
    }

    class { '::elasticsearch::https':
        ferm_srange      => $ferm_srange,
        certificate_name => $certificate_name,
    }
    class { '::elasticsearch::monitor::diamond': }
    class { '::elasticsearch::log::hot_threads': }

}
