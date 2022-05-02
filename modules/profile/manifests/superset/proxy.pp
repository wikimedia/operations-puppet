# == Class profile::superset::proxy
#
# Sets up a WMF HTTP LDAP auth proxy.
#
class profile::superset::proxy (
    Hash $ldap_config          = lookup('ldap', Hash, hash, {}),
    String $x_forwarded_proto  = lookup('profile::superset::proxy::x_forwarded_proto', {'default_value' => 'https'}),
    Boolean $enable_cas        = lookup('profile::superset::enable_cas'),
    String $ferm_srange        = lookup('profile::superset::proxy::ferm_srange', {'default_value' => '$CACHES'}),
    String $server_name        = lookup('profile::superset::server_name'),
) {

    require ::profile::analytics::httpd::utils

    include ::profile::prometheus::apache_exporter

    class { '::httpd':
        modules => ['proxy_http',
                    'proxy',
                    'headers',
                    'auth_basic',
                    'authnz_ldap']
    }

    if $enable_cas {
        profile::idp::client::httpd::site { $server_name:
            vhost_content    => 'profile/idp/client/httpd-superset.erb',
            proxied_as_https => true,
            vhost_settings   => { 'x-forwarded-proto' => $x_forwarded_proto },
            required_groups  => [
                'cn=ops,ou=groups,dc=wikimedia,dc=org',
                'cn=wmf,ou=groups,dc=wikimedia,dc=org',
                'cn=nda,ou=groups,dc=wikimedia,dc=org',
            ]
        }
    } else {
        class { '::passwords::ldap::production': }
        $proxypass = $passwords::ldap::production::proxypass
        $ldap_server_primary = $ldap_config['ro-server']
        $ldap_server_fallback = $ldap_config['ro-server-fallback']

        httpd::site { $server_name:
            content => template('profile/superset/proxy/superset.wikimedia.org.erb'),
            require => File['/var/www/health_check'],
        }
    }

    ferm::service { 'superset-http':
        proto  => 'tcp',
        port   => '80',
        srange => $ferm_srange,
    }
}
