class profile::toolforge::static (
    Stdlib::Fqdn $web_domain = lookup('profile::toolforge::web_domain', {default_value => 'toolforge.org'}),
) {
    $resolver             = join($::nameservers, ' ')
    nginx::site { 'static-server':
        content => template('profile/toolforge/static-server.conf.erb'),
    }
}
