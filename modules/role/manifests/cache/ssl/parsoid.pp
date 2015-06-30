class role::cache::ssl::parsoid {
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
