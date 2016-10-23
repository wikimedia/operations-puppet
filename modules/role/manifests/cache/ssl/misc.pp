class role::cache::ssl::misc {
    include role::cache::ssl::unified

    # In addition to the unified setup most clusters share, misc also needs
    # the two certs/SNIs below:

    tlsproxy::localssl { 'wmfusercontent.org':
        do_ocsp        => true,
        certs          => ['ecc-star.wmfusercontent.org', 'star.wmfusercontent.org'],
        server_name    => 'wmfusercontent.org',
        server_aliases => ['*.wmfusercontent.org'],
        upstream_ports => [3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127],
        redir_port     => 8080,
    }

    tlsproxy::localssl { 'planet.wikimedia.org':
        do_ocsp        => true,
        certs          => ['ecc-star.planet.wikimedia.org', 'star.planet.wikimedia.org'],
        server_name    => 'planet.wikimedia.org',
        server_aliases => ['*.planet.wikimedia.org'],
        upstream_ports => [3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127],
        redir_port     => 8080,
    }
}
