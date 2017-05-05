#
# This class configures elasticsearch
#
# == Parameters:
# [*ferm_srange*]
#   The network range that should be allowed access to elasticsearch. This
#   needs to be customized for elasticsearch clusters serving non production
#   traffic. The relforge cluster is an example.
#   Default: $DOMAIN_NETWORKS
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
    $graylog_hosts = hiera('profile::elasticsearch::graylog_hosts'),
    $rack = hiera('profile::elasticsearch::rack'),
    $row = hiera('profile::elasticsearch::row'),
    $awareness_attributes = hiera('profile::elasticsearch::awareness_attributes'),
    $bulk_thread_pool_executors = hiera('profile::elasticsearch::bulk_thread_pool_executors', 6),
    $certificate_name = hiera('profile::elasticsearch::certificate_name', $::fqdn),
    $recover_after_time = hiera('profile::elasticsearch::recover_after_time', '1s'),
    $recover_after_nodes = hiera('profile::elasticsearch::recover_after_nodes', 1),
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

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }
    # Elasticsearch 5 doesn't allow setting the plugin path, we need
    # to symlink it into place. The directory already exists as part of the
    # debian package, so we need to force the creation of the symlink.
    $plugins_dir = '/srv/deployment/elasticsearch/plugins'
    file { '/usr/share/elasticsearch/plugins':
        ensure  => 'link',
        target  => $plugins_dir,
        force   => true,
        require => Package['elasticsearch/plugins'],
    }

    # Install
    class { '::elasticsearch':
        require                    => [
            Package['elasticsearch/plugins'],
            File['/usr/share/elasticsearch/plugins'],
        ],
        # Production elasticsearch needs these plugins to be loaded in order
        # to work properly.  This will keep elasticsearch from starting
        # if these plugins are  not available.
        plugins_mandatory          => [
            'experimental-highlighter',
            'extra',
            'analysis-icu',
        ],
        plugins_dir                => $plugins_dir,
        # Let apifeatureusage create their indices
        auto_create_index          => '+apifeatureusage-*,-*',
        # Production can get a lot of use out of the filter cache.
        filter_cache_size          => '20%',
        bulk_thread_pool_executors => $bulk_thread_pool_executors,
        bulk_thread_pool_capacity  => 1000,
        rack                       => $rack,
        row                        => $row,
        awareness_attributes       => $awareness_attributes,
        cluster_name               => $cluster_name,
        unicast_hosts              => $unicast_hosts,
        minimum_master_nodes       => $minimum_master_nodes,
        recover_after_time         => $recover_after_time,
        recover_after_nodes        => $recover_after_nodes,
        heap_memory                => $heap_memory,
        expected_nodes             => $expected_nodes,
        master_eligible            => $master_eligible,
        graylog_hosts              => $graylog_hosts,
        version                    => 5,
    }

    class { '::elasticsearch::https':
        ferm_srange      => $ferm_srange,
        certificate_name => $certificate_name,
    }
    class { '::elasticsearch::monitor::diamond': }
    class { '::elasticsearch::log::hot_threads': }

}
