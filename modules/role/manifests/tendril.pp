# manifests/role/tendril.pp
# tendril: MariaDB Analytics

class role::tendril {
    include ::base::firewall
    include standard

    system::role { 'role::tendril': description => 'tendril server' }

    monitoring::service { 'https-tendril':
        description   => 'HTTPS-tendril',
        check_command => 'check_ssl_http_letsencrypt!tendril.wikimedia.org',
    }

    class { '::tendril':
        site_name    => 'tendril.wikimedia.org',
        docroot      => '/srv/tendril/web',
        ldap_binddn  => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        ldap_authurl => 'ldaps://ldap-labs.eqiad.wikimedia.org ldap-labs.codfw.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        ldap_groups  => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
        auth_name    => 'WMF Labs (use wiki login name not shell) - nda/ops/wmf',
    }

    ferm::service { 'tendril-http-https':
        proto => 'tcp',
        port  => '(http https)',
    }
}
