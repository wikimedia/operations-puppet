class profile::thanos::swift::frontend (
    Array $thanos_backends                   = lookup('profile::thanos::backends'),
    Array $thanos_frontends                  = lookup('profile::thanos::frontends'),
    String $swift_cluster                    = lookup('profile::thanos::swift::cluster'),
    Stdlib::Fqdn $service_host               = lookup('profile::thanos::swift::proxy_service_host'),
    Array $memcached_servers                 = lookup('profile::thanos::swift::memcached_servers'),
    Integer $memcached_size_mb               = lookup('profile::thanos::swift::memcached_size_mb'),
    String $hash_path_suffix                 = lookup('profile::thanos::swift::hash_path_suffix'),
    Hash[String, Hash] $swift_accounts       = lookup('profile::thanos::swift::accounts'),
    Hash[String, String] $swift_keys         = lookup('profile::thanos::swift::accounts_keys'),
    String $stats_reporter_host              = lookup('profile::swift::stats_reporter_host'),
    Array[String] $shard_container_list      = lookup('profile::swift::proxy::shard_container_list'),
    Optional[Stdlib::Host] $statsd_host      = lookup('profile::swift::proxy::statsd_host'),
    Optional[Stdlib::Port] $statsd_port      = lookup('profile::swift::proxy::statsd_port'),
    Optional[String] $dispersion_account     = lookup('profile::swift::proxy::dispersion_account'),
    Optional[String] $rewrite_account        = lookup('profile::swift::proxy::rewrite_account'),
    Optional[String] $thumborhost            = lookup('profile::swift::proxy::thumborhost'),
    Optional[String] $inactivedc_thumborhost = lookup('profile::swift::proxy::inactivedc_thumborhost'),
    Optional[String] $read_affinity          = lookup('profile::thanos::swift::read_affinity', { 'default_value' => undef }),
) {
    # TODO: combine this profile with profile::swift::proxy

    class { '::swift':
        hash_path_suffix => $hash_path_suffix,
    }

    class { '::swift::ring':
        swift_cluster => $swift_cluster,
    }

    class { '::swift::proxy':
        shard_container_list   => $shard_container_list,
        statsd_metric_prefix   => "swift.${swift_cluster}.${::hostname}",
        bind_port              => '8888',
        enable_wmf_filters     => false,
        memcached_servers      => $memcached_servers,
        accounts               => $swift_accounts,
        credentials            => $swift_keys,
        proxy_service_host     => $service_host,
        read_affinity          => $read_affinity,
        statsd_host            => $statsd_host,
        statsd_port            => $statsd_port,
        dispersion_account     => $dispersion_account,
        rewrite_account        => $rewrite_account,
        thumborhost            => $thumborhost,
        inactivedc_thumborhost => $inactivedc_thumborhost,
    }

    class { '::memcached':
        size          => $memcached_size_mb,
        port          => 11211,
        # TODO: the following were implicit defaults from
        # MW settings, need to be reviewed.
        growth_factor => 1.05,
        min_slab_size => 5,
    }

    include ::profile::prometheus::memcached_exporter

    class { '::profile::prometheus::statsd_exporter':
        relay_address => '',
    }

    $stats_ensure = $stats_reporter_host == $::fqdn ? {
        true  => present,
        false => absent,
    }

    class { '::profile::swift::stats_reporter':
        ensure        => $stats_ensure,
        swift_cluster => $swift_cluster,
        accounts      => $swift_accounts,
        credentials   => $swift_keys,
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

    $thanos_access = concat($thanos_backends, $thanos_frontends)
    $thanos_access_ferm = join($thanos_access, ' ')

    ferm::service { 'memcached':
        proto   => 'tcp',
        port    => '11211',
        notrack => true,
        srange  => "@resolve((${thanos_access_ferm}))",
    }

    monitoring::service { 'thanos-swift-https':
        description   => 'Thanos swift https',
        check_command => "check_https_url!${service_host}!/healthcheck",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Thanos',
    }
}
