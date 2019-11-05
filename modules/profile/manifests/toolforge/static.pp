class profile::toolforge::static (
    Stdlib::Fqdn $web_domain = lookup('profile::toolforge::web_domain', {default_value => 'tools.wmflabs.org'}),
) {
    $resolver             = join($::nameservers, ' ')

    sslcert::certificate { 'star.wmflabs.org': ensure => absent }
    nginx::site { 'static-server':
        content => template('profile/toolforge/static-server.conf.erb'),
    }
}
