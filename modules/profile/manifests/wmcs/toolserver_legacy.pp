class profile::wmcs::toolserver_legacy(
) {
    class {'::toolserver_legacy': }

    prometheus::blackbox::check::http {
        default:
            server_name         => 'toolserver.org',
            port                => 443,
            ip_families         => ['ip4'],
            prometheus_instance => 'tools',
            team                => 'wmcs',
            severity            => 'warning';

        'toolserver.org main page':
            path               => '/',
            status_matches     => [200],
            body_regex_matches => ['Toolserver was'];

        'toolserver.org redirects':
            path           => '/~legoktm',
            status_matches => [301];
    }
}
