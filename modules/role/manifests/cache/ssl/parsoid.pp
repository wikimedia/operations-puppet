class role::cache::ssl::parsoid {
    role::cache::ssl::local { 'unified':
        certs          => ['uni.wikimedia.org'],
        default_server => true,
        do_ocsp        => true,
    }
}
