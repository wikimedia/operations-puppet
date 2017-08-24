# filtertags: labs-project-deployment-prep labs-project-swift
class role::swift::proxy (
    $use_tls = hiera('role::swift::proxy::use_tls', false),
) {
    system::role { 'swift::proxy':
        description => 'swift frontend proxy',
    }

    include ::standard
    include ::base::firewall
    include ::swift::params
    include ::swift
    include ::swift::ring
    include ::swift::container_sync

    class { '::swift::proxy':
        statsd_metric_prefix => "swift.${::swift::params::swift_cluster}.${::hostname}",
    }

    if $use_tls {
        include ::tlsproxy::nginx_bootstrap

        tlsproxy::localssl { 'unified':
            server_name    => $::swift::proxy::proxy_service_host,
            certs          => [$::swift::proxy::proxy_service_host],
            default_server => true,
            do_ocsp        => false,
        }

        monitoring::service { 'swift-https':
            description   => 'Swift HTTPS',
            check_command => "check_http_url!${::swift::proxy::proxy_service_host}!/monitoring/frontend",
        }

        ferm::service { 'swift-proxy-https':
            proto   => 'tcp',
            notrack => true,
            port    => '443',
        }
    }

    class { '::memcached':
        size => 128,
        port => 11211,
    }

    include role::statsite

    ferm::service { 'swift-proxy':
        proto   => 'tcp',
        notrack => true,
        port    => '80',
    }

    ferm::client { 'swift-object-server':
        proto   => 'tcp',
        notrack => true,
        port    => '6000',
    }

    ferm::client { 'swift-container-server':
        proto   => 'tcp',
        notrack => true,
        port    => '6001',
    }

    ferm::client { 'swift-account-server':
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

    monitoring::service { 'swift-http-frontend':
        description   => 'Swift HTTP frontend',
        check_command => "check_http_url!${::swift::proxy::proxy_service_host}!/monitoring/frontend",
    }
    monitoring::service { 'swift-http-backend':
        description   => 'Swift HTTP backend',
        check_command => "check_http_url!${::swift::proxy::proxy_service_host}!/monitoring/backend",
    }
}

