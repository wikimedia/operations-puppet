# As above, but for misc instead of generic prod
class role::cache::ssl::misc {
    role::cache::ssl::local { 'unified':
        certs          => ['uni.wikimedia.org'],
        default_server => true,
        do_ocsp        => true,
    }

    role::cache::ssl::local { 'wmfusercontent.org':
        do_ocsp        => true,
        certs          => ['star.wmfusercontent.org'],
        server_name    => 'wmfusercontent.org',
        server_aliases => ['*.wmfusercontent.org'];
    }

    role::cache::ssl::local { 'planet.wikimedia.org':
        do_ocsp        => true,
        certs          => ['star.planet.wikimedia.org'],
        server_name    => 'planet.wikimedia.org',
        server_aliases => ['*.planet.wikimedia.org'];
    }
}
