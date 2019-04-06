class profile::swift::proxy_tls {
    require ::profile::tlsproxy::instance

    tlsproxy::localssl { 'unified':
        server_name    => $::swift::proxy::proxy_service_host,
        certs          => [$::swift::proxy::proxy_service_host],
        default_server => true,
        do_ocsp        => false,
    }

    monitoring::service { 'swift-https':
        description   => 'Swift HTTPS',
        check_command => "check_https_url!${::swift::proxy::proxy_service_host}!/monitoring/frontend",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Swift',
    }

    ferm::service { 'swift-proxy-https':
        proto   => 'tcp',
        notrack => true,
        port    => '443',
    }
}