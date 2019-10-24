# filtertags: labs-project-deployment-prep labs-project-swift
class role::swift::proxy (
    $use_tls = hiera('role::swift::proxy::use_tls', false),
) {
    system::role { 'swift::proxy':
        description => 'swift frontend proxy',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::swift::params
    include ::swift
    include ::swift::ring
    include ::swift::container_sync

    include ::profile::conftool::client
    class { 'conftool::scripts': }


    class { '::swift::proxy':
        statsd_metric_prefix => "swift.${::swift::params::swift_cluster}.${::hostname}",
    }

    if $use_tls {
        include ::profile::swift::proxy_tls
    }

    class { '::memcached':
        size => 128,
        port => 11211,
    }

    include ::profile::prometheus::memcached_exporter

    include ::profile::statsite
    class { '::profile::prometheus::statsd_exporter':
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

    $swift_backends = hiera('swift::storagehosts')
    $swift_frontends = hiera('swift::proxyhosts')
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
}
