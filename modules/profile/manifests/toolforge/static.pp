class profile::toolforge::static (
    Stdlib::Fqdn $static_domain = lookup('profile::toolforge::static::static_domain', {default_value => 'tools-static.wmflabs.org'}),
    Stdlib::Fqdn $web_domain    = lookup('profile::toolforge::web_domain', {default_value => 'toolforge.org'}),
) {
    class { 'haproxy': }

    haproxy::site { 'static':
        content => template('profile/toolforge/static/haproxy.cfg.erb'),
    }

    include profile::resolving
    $resolver = $profile::resolving::nameserver_ips
        .map |$ip| {
            wmflib::ip_family($ip) ? {
                4 => $ip,
                6 => "[${ip}]",
            }
        }
        .join(' ')

    $errors_dir = '/var/www/errors'
    $fingerprints_dir = '/var/www/fingerprints'

    wmflib::dir::mkdir_p([
        $errors_dir,
        $fingerprints_dir,
    ])

    file { "${errors_dir}/favicon.ico":
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/static/errors/favicon.ico',
    }

    file { "${errors_dir}/toolforge-logo.png":
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/static/errors/toolforge-logo.png',
    }

    file { "${errors_dir}/toolforge-logo-2x.png":
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/static/errors/toolforge-logo-2x.png',
    }

    nginx::site { 'static-server':
        content => template('profile/toolforge/static/nginx.conf.erb'),
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
