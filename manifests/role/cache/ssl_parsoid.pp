class role::cache::ssl_parsoid {
    # Explicitly not adding wmf CA since it is not needed for now
    include role::protoproxy::ssl::common

    role::cache::localssl { 'unified':
        certname       => 'uni.wikimedia.org',
        default_server => true,
    }
    role::cache::localssl { 'wikimedia.org':
        certname       => 'sni.wikimedia.org',
        server_name    => 'wikimedia.org',
        server_aliases => ['*.wikimedia.org'],
    }
    role::cache::localssl { 'm.wikimedia.org':
        certname       => 'sni.m.wikimedia.org',
        server_name    => 'm.wikimedia.org',
        server_aliases => ['*.m.wikimedia.org'],
    }
}
