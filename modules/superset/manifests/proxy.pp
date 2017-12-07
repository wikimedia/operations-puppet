# == Class superset::proxy
# Sets up a WMF HTTP LDAP auth proxy.
#
class superset::proxy {
    include ::apache::mod::proxy_http
    include ::apache::mod::proxy
    include ::apache::mod::auth_basic
    include ::apache::mod::authnz_ldap
    include ::apache::mod::headers
    include ::passwords::ldap::production

    $proxypass = $passwords::ldap::production::proxypass

    # Set up the VirtualHost
    apache::site { 'superset.wikimedia.org':
        content => template('superset/superset.wikimedia.org.erb'),
    }

    ferm::service { 'superset-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }
}
