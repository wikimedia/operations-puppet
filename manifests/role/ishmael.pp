# manifests/role/ishmael.pp
# ishmael: A UI for mk-query-digest
class role::ishmael {

    system::role { 'role::ishmael': description => 'ishmael server' }

    class { 'ishmael':
        site_name      => 'ishmael.wikimedia.org',
        ssl_cert       => 'star.wikimedia.org',
        ssl_ca         => 'RapidSSL_CA',
        $config_main   => '/srv/ishmael/conf.php',
        $config_sample => '/srv/ishmael/sample/conf.php',
        $docroot       => '/srv/ishmael',
        $ldap_binddn   => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        $ldap_authurl  => 'ldaps://virt0.wikimedia.org virt1000.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        $ldap_group    => 'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        $auth_name     => 'WMF Labs (use wiki login name not shell)',
    }

}
