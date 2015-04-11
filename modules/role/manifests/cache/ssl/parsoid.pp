class role::cache::ssl::parsoid {
    # Explicitly not adding wmf CA since it is not needed for now
    include role::protoproxy::ssl::common

    role::cache::ssl::local { 'unified':
        certname       => 'uni.wikimedia.org',
        default_server => true,
    }
    role::cache::ssl::local { 'wikimedia.org':
        certname       => 'sni.wikimedia.org',
        server_name    => 'wikimedia.org',
        server_aliases => ['*.wikimedia.org'],
    }
    role::cache::ssl::local { 'm.wikimedia.org':
        certname       => 'sni.m.wikimedia.org',
        server_name    => 'm.wikimedia.org',
        server_aliases => ['*.m.wikimedia.org'],
    }
}
