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
class role::elasticsearch::common(
    $ferm_srange      = '$DOMAIN_NETWORKS',
) {

    if ($::realm == 'production' and hiera('elasticsearch::rack', undef) == undef) {
        fail("Don't know rack for ${::hostname} and rack awareness should be turned on")
    }

    if ($::realm == 'labs' and hiera('elasticsearch::cluster_name', undef) == undef) {
        $msg = '\$::elasticsearch::cluster_name must be set to something unique to the labs project.'
        $msg2 = 'You can set it in the hiera config of the project'
        fail("${msg}\n${msg2}")
    }

    if hiera('has_lvs', true) {
        include ::lvs::realserver
    }

    ferm::service { 'elastic-http':
        proto   => 'tcp',
        port    => '9200',
        notrack => true,
        srange  => $ferm_srange,
    }

    $elastic_nodes = hiera('elasticsearch::cluster_hosts')
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
        bulk_thread_pool_executors => hiera('elasticsearch::bulk_thread_pool_executors', 5),
        bulk_thread_pool_capacity  => 1000,
    }

    include ::standard
    if $::standard::has_ganglia {
        include ::elasticsearch::ganglia
    }

    class { '::elasticsearch::https':
        ferm_srange => $ferm_srange,
    }
    include elasticsearch::monitor::diamond
    include ::elasticsearch::log::hot_threads

}
