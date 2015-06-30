# As above, but for misc instead of generic prod
class role::cache::ssl::misc {
    role::cache::ssl::local { 'wikimedia.org':
        do_ocsp        => true,
        certname       => 'sni.wikimedia.org',
        server_name    => 'wikimedia.org',
        server_aliases => ['*.wikimedia.org'],
        default_server => true;
    }

    role::cache::ssl::local { 'wmfusercontent.org':
        do_ocsp        => true,
        certname       => 'star.wmfusercontent.org',
        server_name    => 'wmfusercontent.org',
        server_aliases => ['*.wmfusercontent.org'];
    }

    role::cache::ssl::local { 'planet.wikimedia.org':
        do_ocsp        => true,
        certname       => 'star.planet.wikimedia.org',
        server_name    => 'planet.wikimedia.org',
        server_aliases => ['*.planet.wikimedia.org'];
    }
}
