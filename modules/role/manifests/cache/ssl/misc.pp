class role::cache::ssl::misc {
    include role::cache::ssl::unified

    # In addition to the unified setup most clusters share, misc also needs
    # the two certs/SNIs below:

    tlsproxy::localssl { 'wmfusercontent.org':
        do_ocsp        => true,
        certs          => ['ecc-star.wmfusercontent.org', 'star.wmfusercontent.org'],
        server_name    => 'wmfusercontent.org',
        server_aliases => ['*.wmfusercontent.org'];
    }

    tlsproxy::localssl { 'planet.wikimedia.org':
        certs          => ['star.planet.wikimedia.org'],
        server_name    => 'planet.wikimedia.org',
        server_aliases => ['*.planet.wikimedia.org'];
    }
}
