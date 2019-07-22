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
    Stdlib::Fqdn $ldap_server,
    Stdlib::Fqdn $ldap_server_fallback,
    Stdlib::Fqdn $server_name = 'turnilo.wikimedia.org',
) {
    Class['turnilo'] -> Class['turnilo::proxy']

    $proxypass = $passwords::ldap::production::proxypass

    # local variable for use int template.
    $turnilo_port = $turnilo::port

    # Set up the VirtualHost
    httpd::site { $server_name:
        content => template('turnilo/turnilo.vhost.erb'),
    }
}
