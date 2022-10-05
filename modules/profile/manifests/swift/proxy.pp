# SPDX-License-Identifier: Apache-2.0
class profile::swift::proxy (
    Hash $accounts                             = lookup('profile::swift::accounts'),
    Hash $accounts_keys                        = lookup('profile::swift::accounts_keys'),
    Hash[String, Hash] $replication_accounts   = lookup('profile::swift::replication_accounts'),
    Hash[String, Hash] $replication_keys       = lookup('profile::swift::replication_keys'),
    String $hash_path_suffix                   = lookup('profile::swift::hash_path_suffix'),
    String $stats_reporter_host                = lookup('profile::swift::stats_reporter_host'),
    Swift::Clusters $swift_clusters            = lookup('swift_clusters'),
    String $swift_cluster_label                = lookup('profile::swift::cluster_label'),
    Array[Stdlib::Host] $swift_backends        = lookup('profile::swift::storagehosts'),
    Array[Stdlib::Host] $swift_frontends       = lookup('profile::swift::proxyhosts'),
    Boolean $use_tls                           = lookup('profile::swift::proxy::use_tls'),
    String $proxy_service_host                 = lookup('profile::swift::proxy::proxy_service_host'),
    Array[String] $shard_container_list        = lookup('profile::swift::proxy::shard_container_list'),
    Hash[String, Puppetmaster::Backends] $puppet_servers = lookup('puppetmaster::servers'),
    Optional[Stdlib::Host] $statsd_host        = lookup('profile::swift::proxy::statsd_host'),
    Optional[Stdlib::Port] $statsd_port        = lookup('profile::swift::proxy::statsd_port'),
    Optional[String] $dispersion_account       = lookup('profile::swift::proxy::dispersion_account'),
    Optional[String] $rewrite_account          = lookup('profile::swift::proxy::rewrite_account'),
    Optional[Array[String]] $memcached_servers = lookup('profile::swift::proxy::memcached_servers'),
    Optional[String] $thumborhost              = lookup('profile::swift::proxy::thumborhost'),
    Optional[String] $inactivedc_thumborhost   = lookup('profile::swift::proxy::inactivedc_thumborhost'),
    Boolean $enable_swiftrepl                  = lookup('profile::swift::proxy::enable_swiftrepl'),
){

    class { 'swift':
        hash_path_suffix => $hash_path_suffix,
    }

    class { 'swift::container_sync':
        accounts => $replication_accounts,
        keys     => $replication_keys,
    }

    $swift_cluster_name = $swift_clusters[$swift_cluster_label]['cluster_name']

    class { 'swift::ring':
        swift_cluster => $swift_cluster_name,
    }

    class { 'conftool::scripts': }

    $stats_ensure = ($stats_reporter_host == $facts['networking']['fqdn']).bool2str('present','absent')

    class { 'swift::stats_reporter':
        ensure        => $stats_ensure,
        swift_cluster => $swift_cluster_name,
        accounts      => $accounts,
        credentials   => $accounts_keys,
    }

    swift::stats::stats_container { 'mw-media':
        ensure        => $stats_ensure,
        account_name  => 'AUTH_mw',
        container_set => 'mw-media',
        statsd_host   => $statsd_host,
        statsd_port   => $statsd_port,
        statsd_prefix => "swift.${swift_cluster_name}.containers.mw-media",
    }

    class { 'swift::proxy':
        proxy_service_host     => $proxy_service_host,
        shard_container_list   => $shard_container_list,
        statsd_metric_prefix   => "swift.${swift_cluster_name}.${facts['networking']['hostname']}",
        accounts               => $accounts,
        credentials            => $accounts_keys,
        statsd_host            => $statsd_host,
        statsd_port            => $statsd_port,
        dispersion_account     => $dispersion_account,
        rewrite_account        => $rewrite_account,
        memcached_servers      => $memcached_servers,
        thumborhost            => $thumborhost,
        inactivedc_thumborhost => $inactivedc_thumborhost,
    }

    if $use_tls {
        include profile::swift::proxy_tls
    }

    if $enable_swiftrepl {
        include profile::swift::swiftrepl
    }

    class { 'memcached':
        size          => 128,
        port          => 11211,
        # TODO: the following were implicit defaults from
        # MW settings, need to be reviewed.
        growth_factor => 1.05,
        min_slab_size => 5,
    }

    class { 'profile::prometheus::statsd_exporter':
        relay_address => '',
    }

    ferm::service { 'swift-proxy':
        proto   => 'tcp',
        notrack => true,
        port    => '80',
    }

    ferm::client { 'swift-object-server-client':
        proto   => 'tcp',
        notrack => true,
        port    => '6000',
    }

    # Per-disk object-server ports T222366
    ferm::client { 'swift-object-server-client-disks':
        proto   => 'tcp',
        notrack => true,
        port    => '(6010:6040)'
    }

    ferm::client { 'swift-container-server-client':
        proto   => 'tcp',
        notrack => true,
        port    => '6001',
    }

    ferm::client { 'swift-account-server-client':
        proto   => 'tcp',
        notrack => true,
        port    => '6002',
    }

    $swift_access = concat($swift_backends, $swift_frontends)
    $swift_access_ferm = join($swift_access, ' ')

    ferm::service { 'swift-memcached':
        proto   => 'tcp',
        port    => '11211',
        notrack => true,
        srange  => "@resolve((${swift_access_ferm}))",
    }

    $http_s = $use_tls ? {
        true  => 'https',
        false => 'http',
    }
    monitoring::service { "swift-${http_s}-frontend":
        description   => "Swift ${http_s} frontend",
        check_command => "check_${http_s}_url!${::swift::proxy::proxy_service_host}!/monitoring/frontend",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Swift',
    }
    monitoring::service { "swift-${http_s}-backend":
        description   => "Swift ${http_s} backend",
        check_command => "check_${http_s}_url!${::swift::proxy::proxy_service_host}!/monitoring/backend",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Swift',
    }


    $ring_manager_ensure = $swift_clusters[$swift_cluster_label]['ring_manager'] ? {
        $facts['networking']['fqdn'] => 'present',
        default => 'absent',
    }
    class { 'rsync::server':
        ensure_service => stdlib::ensure($ring_manager_ensure, 'service'),
    }

    class { 'swift::ring_manager':
        ensure        => $ring_manager_ensure,
        swift_cluster => $swift_cluster_name,
        puppetmasters => keys($puppet_servers),
    }
}
