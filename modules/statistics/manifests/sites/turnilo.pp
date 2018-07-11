# == Class statistics::sites::turnilo
# turnilo.wikimedia.org
#
# This site is composed by two parts:
# 1) a simple Apache reverse proxy to limit the access to authenticated
#    clients (via LDAP);
# 2) a nodejs application (Turnilo) deployed via scap (not part of
#    this class).
#
class statistics::sites::turnilo($turnilo_port = 9091) {
    require ::statistics::web

    include ::apache::mod::proxy_http
    include ::apache::mod::proxy
    include ::apache::mod::auth_basic
    include ::apache::mod::authnz_ldap
    include ::passwords::ldap::production

    $proxypass = $passwords::ldap::production::proxypass

    # Set up the VirtualHost
    apache::site { 'turnilo.wikimedia.org':
        content => template('statistics/turnilo.wikimedia.org.erb'),
    }

    ferm::service { 'turnilo-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

}
