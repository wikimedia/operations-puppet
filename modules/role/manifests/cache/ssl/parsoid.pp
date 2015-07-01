class role::cache::ssl::parsoid {
    role::cache::ssl::local { 'unified':
        certs          => ['uni.wikimedia.org'],
        default_server => true,
    }
    role::cache::ssl::local { 'wikimedia.org':
        certs          => ['sni.wikimedia.org'],
        server_name    => 'wikimedia.org',
        server_aliases => ['*.wikimedia.org'],
    }
    role::cache::ssl::local { 'm.wikimedia.org':
        certs          => ['sni.m.wikimedia.org'],
        server_name    => 'm.wikimedia.org',
        server_aliases => ['*.m.wikimedia.org'],
    }
}
