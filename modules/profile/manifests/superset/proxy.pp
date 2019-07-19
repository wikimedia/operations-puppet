# == Class profile::superset::proxy
#
# Sets up a WMF HTTP LDAP auth proxy.
#
class profile::superset::proxy {

    require ::profile::analytics::httpd::utils

    class { '::httpd':
        modules => ['proxy_http',
                    'proxy',
                    'headers',
                    'auth_basic',
                    'authnz_ldap']
    }

    class { '::passwords::ldap::production': }

    $proxypass = $passwords::ldap::production::proxypass

    # Set up the VirtualHost
    httpd::site { 'superset.wikimedia.org':
        content => template('profile/superset/proxy/superset.wikimedia.org.erb'),
        require => File['/var/www/health_check'],
    }

    ferm::service { 'superset-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
