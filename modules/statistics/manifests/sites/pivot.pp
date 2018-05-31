# == Class statistics::sites::pivot
# pivot.wikimedia.org
#
# This site is a simple redirect to turnilo.wikimedia.org
#
class statistics::sites::pivot {
    require ::statistics::web

    include ::apache::mod::proxy_http
    include ::apache::mod::proxy
    include ::apache::mod::auth_basic
    include ::apache::mod::authnz_ldap
    include ::passwords::ldap::production

    $proxypass = $passwords::ldap::production::proxypass

    # Set up the VirtualHost
    apache::site { 'pivot.wikimedia.org':
        ensure  => 'absent',
        content => template('statistics/pivot.wikimedia.org.erb'),
    }

    ferm::service { 'pivot-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }

}
