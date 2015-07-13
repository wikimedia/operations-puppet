class role::cache::ssl::unified {
    role::cache::ssl::local { 'unified':
        certs          => ['ecc-uni.wikimedia.org', 'uni.wikimedia.org'],
        default_server => true,
        do_ocsp        => true,
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_sslxNN',
    }
}
