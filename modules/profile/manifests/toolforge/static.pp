class profile::toolforge::static (
    Stdlib::Fqdn $static_domain = lookup('profile::toolforge::static::static_domain', {default_value => 'tools-static.wmflabs.org'}),
    Stdlib::Fqdn $web_domain    = lookup('profile::toolforge::web_domain', {default_value => 'toolforge.org'}),
) {
    include profile::resolving
    $resolver = $profile::resolving::nameserver_ips.join(' ')
    $fingerprints_dir = '/var/www/fingerprints'

    wmflib::dir::mkdir_p($fingerprints_dir)

    nginx::site { 'static-server':
        content => template('profile/toolforge/static-server.conf.erb'),
    }

    class { 'ssh::publish_fingerprints':
        document_root => $fingerprints_dir,
    }

    prometheus::blackbox::check::http { $static_domain:
        port                => 80,
        # this should always exist
        path                => '/admin/fingerprints/',
        ip_families         => ['ip4'],
        prometheus_instance => 'tools',
        team                => 'wmcs',
        severity            => 'warning',
    }
}
