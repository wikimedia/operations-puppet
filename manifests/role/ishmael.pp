# manifests/role/ishmael.pp
# ishmael: A UI for mk-query-digest
class role::ishmael {

    system::role { 'role::ishmael': description => 'ishmael server' }

    install_certificate{ 'ishmael.wikimedia.org': ca => 'RapidSSL_CA.pem' }
    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')

    class { '::ishmael':
        site_name     => 'ishmael.wikimedia.org',
        config_main   => '/srv/ishmael/conf.php',
        config_sample => '/srv/ishmael/sample/conf.php',
        docroot       => '/srv/ishmael',
        ldap_binddn   => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        ldap_authurl  => 'ldaps://virt0.wikimedia.org virt1000.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        ldap_groups   => [ 'cn=ops,ou=groups,dc=wikimedia,dc=org', 'cn=wmf,ou=groups,dc=wikimedia,dc=org', 'cn=nda,ou=groups,dc=wikimedia,dc=org' ],
        auth_name     => 'WMF Labs (use wiki login name not shell)',
    }

}
