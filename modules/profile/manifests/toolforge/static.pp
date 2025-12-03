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
    $meta_dir = '/var/www/meta'

    # TODO: Maybe fingerprints_dir should be merged into meta_dir?
    wmflib::dir::mkdir_p([
        $errors_dir,
        $fingerprints_dir,
        $meta_dir,
    ])

    file { "${errors_dir}/favicon.ico":
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/favicon.ico',
    }

    file { "${errors_dir}/toolforge-logo.png":
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/static/errors/toolforge-logo.png',
    }

    file { "${errors_dir}/toolforge-logo-2x.png":
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/static/errors/toolforge-logo-2x.png',
    }

    $worker_ranges = wmflib::class::hosts('profile::toolforge::k8s::worker')
        .wmflib::hosts2ips()
        .map |$ip| { wmflib::ip2cidr($ip) }
    # Hardcoded since we don't have a good way of updating it automatically.
    $creation_time = '2025-12-03T12:06:00.000000'

    file { "${meta_dir}/worker-ips.json":
        ensure  => file,
        content => wmflib::googlebot_ranges_json($worker_ranges, $creation_time).to_json(),
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
