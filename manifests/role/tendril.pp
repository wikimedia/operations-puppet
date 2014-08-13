# manifests/role/tendril.pp
# tendril: MariaDB Analytics

class role::tendril {

    system::role { 'role::tendril': description => 'tendril server' }

    install_certificate{ 'tendril.wikimedia.org': }
    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')

    class { '::tendril':
        site_name     => 'tendril.wikimedia.org',
        docroot       => '/srv/tendril/web',
        ldap_binddn   => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        ldap_authurl  => 'ldaps://virt0.wikimedia.org virt1000.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        ldap_groups   => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
        auth_name     => 'WMF Labs (use wiki login name not shell)',
    }

}
