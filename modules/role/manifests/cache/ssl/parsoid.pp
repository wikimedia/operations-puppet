class role::cache::ssl::parsoid {
    role::cache::ssl::local { 'unified':
        certs          => ['ecc-uni.wikimedia.org', 'uni.wikimedia.org'],
        default_server => true,
        do_ocsp        => true,
    }
}
