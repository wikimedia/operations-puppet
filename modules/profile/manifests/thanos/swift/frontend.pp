class profile::thanos::swift::frontend (
    Array $thanos_backends = lookup('profile::thanos::backends'),
    Array $thanos_frontends = lookup('profile::thanos::frontends'),
    String $swift_cluster = lookup('profile::thanos::swift::cluster'),
    Stdlib::Fqdn $service_host = lookup('profile::thanos::swift::proxy_service_host'),
    Array $memcached_servers = lookup('profile::thanos::swift::memcached_servers'),
    String $hash_path_suffix = lookup('profile::thanos::swift::hash_path_suffix'),
    Hash[String, Hash] $swift_accounts = lookup('profile::thanos::swift::accounts'),
    Hash[String, String] $swift_keys = lookup('profile::thanos::swift::accounts_keys'),
    String $stats_reporter_host = lookup('profile::swift::stats_reporter_host'),
) {

    class { '::swift':
        hash_path_suffix => $hash_path_suffix,
    }

    class { '::swift::ring':
        swift_cluster => $swift_cluster,
    }

    class { '::swift::proxy':
        statsd_metric_prefix => "swift.${swift_cluster}.${::hostname}",
        bind_port            => '8888',
        enable_wmf_filters   => false,
        memcached_servers    => $memcached_servers,
        accounts             => $swift_accounts,
        credentials          => $swift_keys,
        proxy_service_host   => $service_host,
    }

    class { '::memcached':
        size          => 128,
        port          => 11211,
        # TODO: the following were implicit defaults from
        # MW settings, need to be reviewed.
        growth_factor => 1.05,
        min_slab_size => 5,
    }

    include ::profile::prometheus::memcached_exporter

    include ::profile::statsite
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
    range(6010, 6030).each |$port| {
        ferm::client { "swift-object-server-client-${port}":
            proto   => 'tcp',
            notrack => true,
            port    => $port,
        }
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
