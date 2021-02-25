class ldap::config::labs {
    $hieraldapconfig = hiera_hash('labsldapconfig', {})

    $basedn = 'dc=wikimedia,dc=org'
    $servernames = [ $hieraldapconfig['hostname'] ]
    $sudobasedn = $::realm ? {
        'labs'       => "ou=sudoers,cn=${::labsproject},ou=projects,${basedn}",
        'production' => "ou=sudoers,${basedn}"
    }

    $ldapconfig = {
        'servernames'          => $servernames,
        'basedn'               => $basedn,
        'groups_rdn'           => 'ou=groups',
        'users_rdn'            => 'ou=people',
        'domain'               => 'wikimedia',
        'proxyagent'           => "cn=proxyagent,ou=profile,${basedn}",
        'proxypass'            => $hieraldapconfig['proxypass'],
        'script_user_dn'       => "cn=scriptuser,ou=profile,${basedn}",
        'script_user_pass'     => $hieraldapconfig['script_user_pass'],
        'user_id_attribute'    => 'uid',
        'tenant_id_attribute'  => 'cn',
        'ca'                   => 'ca-certificates.crt',
        'sudobasedn'           => $sudobasedn,
        'pagesize'             => '2000',
        'nss_min_uid'          => '499',
    }
}
