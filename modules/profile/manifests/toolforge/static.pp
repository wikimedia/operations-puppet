class profile::toolforge::static (
    Stdlib::Fqdn $web_domain = lookup('profile::toolforge::web_domain', {default_value => 'toolforge.org'}),
) {
    $resolver = join($::nameservers, ' ')
    $fingerprints_dir = '/var/www/fingerprints'

    wmflib::dir::mkdir_p($fingerprints_dir)

    nginx::site { 'static-server':
        content => template('profile/toolforge/static-server.conf.erb'),
    }

    class { 'ssh::publish_fingerprints':
        document_root => $fingerprints_dir,
    }
}
