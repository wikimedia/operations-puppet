class role::cache::ssl::unified {

    if $::hostname == 'cp1008' {
        $certs = ['ecc-uni.wikimedia.org', 'uni.wikimedia.org']
    } else {
        $certs = ['uni.wikimedia.org']
    }

    role::cache::ssl::local { 'unified':
        certs          => $certs,
        default_server => true,
        do_ocsp        => true,
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_sslxNN',
    }
}
