class profile::toolforge::static (
    Stdlib::Fqdn $web_domain = lookup('profile::toolforge::web_domain', {default_value => 'tools.wmflabs.org'}),
) {
    $resolver             = join($::nameservers, ' ')
    $ssl_settings         = ssl_ciphersuite('nginx', 'compat')
    $ssl_certificate_name = 'star.wmflabs.org'

    sslcert::certificate { $ssl_certificate_name: }
    nginx::site { 'static-server':
        content => template('profile/toolforge/static-server.conf.erb'),
    }
}
