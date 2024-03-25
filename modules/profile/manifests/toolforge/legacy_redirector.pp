class profile::toolforge::legacy_redirector (
    Optional[String[1]] $ssl_certificate_name = lookup('profile::toolforge::legacy_redirector::ssl_certificate_name', {default_value => 'tools-legacy'}),
) {
    $ssl_settings = ssl_ciphersuite('apache', 'compat')
    if $ssl_certificate_name {
        acme_chief::cert { $ssl_certificate_name:
            puppet_svc => 'apache2',
        }
    }

    class { 'httpd':
        modules => ['alias', 'rewrite', 'ssl'],
    }

    httpd::site { 'tools.wmflabs.org':
        content => template('profile/toolforge/legacy_redirector/tools.wmflabs.org.conf.erb'),
    }

    httpd::site { 'www.toolserver.org':
        content => template('profile/toolforge/legacy_redirector/www.toolserver.org.conf.erb'),
    }

    file { '/var/www/www.toolserver.org':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/profile/toolforge/legacy_redirector/www.toolserver.org/',
        recurse => true,
        purge   => true,
    }

    ferm::service { 'http':
        proto => 'tcp',
        port  => '80',
        desc  => 'HTTP webserver for the entire world',
    }
    if $ssl_certificate_name {
        ferm::service { 'https':
            proto => 'tcp',
            port  => '443',
            desc  => 'HTTPS webserver for the entire world',
        }
    }

    if $ssl_certificate_name {
        $monitor_port = 443
    } else {
        $monitor_port = 80
    }

    prometheus::blackbox::check::http {
        default:
            port                => $monitor_port,
            ip_families         => ['ip4'],
            prometheus_instance => 'tools',
            team                => 'wmcs',
            severity            => 'warning';

        'tools.wmflabs.org main page':
            server_name    => 'tools.wmflabs.org',
            path           => '/',
            status_matches => [302],
            header_matches => [{ 'header' => 'Location', 'regexp' => '^https://toolforge.org/$' }];

        'tools.wmflabs.org tool':
            server_name    => 'tools.wmflabs.org',
            path           => '/sal/aaa',
            status_matches => [308],
            header_matches => [{ 'header' => 'Location', 'regexp' => '^https://sal.toolforge.org/aaa$' }];

        'toolserver.org main page':
            server_name        => 'toolserver.org',
            path               => '/',
            status_matches     => [200],
            body_regex_matches => ['Toolserver was'];

        'toolserver.org redirects':
            server_name    => 'toolserver.org',
            path           => '/~legoktm',
            status_matches => [301],
            header_matches => [{ 'header' => 'Location', 'regexp' => '^https://meta.wikimedia.org/wiki/User:Legoktm/Toolserver\\?from=$' }];
    }
}
