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
class profile::elasticsearch::common (
    $has_lvs                    = hiera('has_lvs', true),
    $ferm_srange                = hiera('elasticsearch::ferm_srange', '$DOMAIN_NETWORKS'),
    $rack                       = hiera('elasticsearch::rack', undef),
    $row                        = hiera('elasticsearch::row', undef),
    $cluster_name               = hiera('elasticsearch::cluster_name', undef),
    $bulk_thread_pool_executors = hiera('elasticsearch::bulk_thread_pool_executors', 6),
    $elastic_nodes              = hiera('elasticsearch::cluster_hosts'),
    $unicast_hosts              = hiera('elasticsearch::unicast_hosts', []),
    $version                    = hiera('elasticsearch::version', 5),
    $minimum_master_nodes       = hiera('elasticsearch::minimum_master_nodes', 1),
    $certificate_name           = hiera('elasticsearch::https::certificate_name', $::fqdn),
    $recover_after_time         = hiera('elasticsearch::recover_after_time', '1s'),
    $recover_after_nodes        = hiera('elasticsearch::recover_after_nodes', 1),
    $heap_memory                = hiera('elasticsearch::heap_memory', '2G'),
    $expected_nodes             = hiera('elasticsearch::expected_nodes', 1),
    $master_eligible            = hiera('elasticsearch::master_eligible', false),
    $graylog_hosts              = hiera('elasticsearch::graylog_hosts', undef),
    $auto_create_index          = hiera('elasticsearch::auto_create_index', false),
) {

    if ($::realm == 'production' and $rack == undef) {
        fail("Don't know rack for ${::hostname} and rack awareness should be turned on")
    }

    if ($::realm == 'labs' and $cluster_name == undef) {
        $msg = '\$::elasticsearch::cluster_name must be set to something unique to the labs project.'
        $msg2 = 'You can set it in the hiera config of the project'
        fail("${msg}\n${msg2}")
    }

    if $has_lvs {
        class { '::lvs::realserver': }
    }
    class { '::standard': }

    ferm::service { 'elastic-http':
        proto   => 'tcp',
        port    => '9200',
        notrack => true,
        srange  => $ferm_srange,
    }

    $elastic_nodes_ferm = join($elastic_nodes, ' ')

    ferm::service { 'elastic-inter-node':
        proto   => 'tcp',
        port    => '9300',
        notrack => true,
        srange  => "@resolve((${elastic_nodes_ferm}))",
    }

    system::role { 'role::elasticsearch::server':
        ensure      => 'present',
        description => 'elasticsearch server',
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
        cluster_name               => $cluster_name,
        unicast_hosts              => $unicast_hosts,
        version                    => $version,
        minimum_master_nodes       => $minimum_master_nodes,
        recover_after_time         => $recover_after_time,
        recover_after_nodes        => $recover_after_nodes,
        heap_memory                => $heap_memory,
        expected_nodes             => $expected_nodes,
        master_eligible            => $master_eligible,
        graylog_hosts              => $graylog_hosts,
        auto_create_index          => $auto_create_index,
    }

    if $::standard::has_ganglia {
        class { '::elasticsearch::ganglia': }
    }

    class { '::elasticsearch::https':
        ferm_srange => $ferm_srange,
        certificate_name => $certificate_name,
    }
    class { '::elasticsearch::monitor::diamond': }
    class { '::elasticsearch::log::hot_threads': }

}
