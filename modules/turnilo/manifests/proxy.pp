# == Class turnilo::proxy
#
# Sets up an apache http proxy with WMF ldap authentication.
# To login, you must be in either the wmf or ops ldap group.
#
# This class can only be used on the same host running turnilo.
#
# == Parameters
# [*server_name*]
#   VirtualHost ServerName hostname to use.
class turnilo::proxy(
    $server_name = 'turnilo.wikimedia.org'
) {
    Class['turnilo'] -> Class['turnilo::proxy']

    # Ignore wmf styleguide; I should be able to use Apache classes from a module. >:o
    # lint:ignore:wmf_styleguide
    class { '::apache::mod::proxy_http': }
    class { '::apache::mod::proxy': }
    class { '::apache::mod::auth_basic': }
    class { '::apache::mod::authnz_ldap': }
    class { '::passwords::ldap::production': }
    # lint:endignore

    $proxypass = $passwords::ldap::production::proxypass

    # local variable for use int template.
    $turnilo_port = $turnilo::port

    # Set up the VirtualHost
    apache::site { $server_name:
        content => template('turnilo/turnilo.vhost.erb'),
    }

    ferm::service { 'turnilo-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
