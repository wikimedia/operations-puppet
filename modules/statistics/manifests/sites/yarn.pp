# == Class statistics::sites::yarn
# yarn.wikimedia.org
#
# This site will be a simple reverse proxy to analytics1001,
# uset to limit the access to authenticated clients (via LDAP).
#
# Bug: T116192
#
class statistics::sites::yarn {
    require ::statistics::web

    include ::apache::mod::proxy_http
    include ::apache::mod::proxy
    include ::apache::mod::proxy_html
    include ::apache::mod::xml2enc
    include ::apache::mod::auth_basic
    include ::apache::mod::authnz_ldap
    include ::passwords::ldap::production

    $proxypass = $passwords::ldap::production::proxypass

    # Set up the VirtualHost
    apache::site { 'yarn.wikimedia.org':
        content => template('statistics/yarn.wikimedia.org.erb'),
    }

    ferm::service { 'yarn-http':
        proto => 'tcp',
        port  => '80',
    }

}