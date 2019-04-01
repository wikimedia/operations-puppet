class profile::swift::proxy_tls (
    String $ocsp_proxy   = hiera('http_proxy', ''),
) {
    require ::profile::tlsproxy::instance

    tlsproxy::localssl { 'unified':
        server_name    => $::swift::proxy::proxy_service_host,
        certs          => [$::swift::proxy::proxy_service_host],
        default_server => true,
        do_ocsp        => false,
        ocsp_proxy     => $ocsp_proxy,
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
