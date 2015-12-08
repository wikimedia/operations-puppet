class ldap::role::config::labs {
    include passwords::ldap::labs

    $basedn = 'dc=wikimedia,dc=org'
    $servernames = $site ? {
        'eqiad' => [ 'ldap-labs.eqiad.wikimedia.org', 'ldap-labs.codfw.wikimedia.org' ],
        'codfw' => [ 'ldap-labs.codfw.wikimedia.org', 'ldap-labs.eqiad.wikimedia.org' ],
    }
    $sudobasedn = $::realm ? {
        'labtest'       => "ou=sudoers,cn=${labsproject},ou=projects,${basedn}",
        'labs'       => "ou=sudoers,cn=${labsproject},ou=projects,${basedn}",
        'production' => "ou=sudoers,${basedn}"
    }

    $ldapconfig = {
        'servernames'          => $servernames,
        'basedn'               => $basedn,
        'groups_rdn'           => 'ou=groups',
        'users_rdn'            => 'ou=people',
        'domain'               => 'wikimedia',
        'proxyagent'           => "cn=proxyagent,ou=profile,${basedn}",
        'proxypass'            => $passwords::ldap::labs::proxypass,
        'writer_dn'            => "uid=novaadmin,ou=people,${basedn}",
        'writer_pass'          => $passwords::ldap::labs::writerpass,
        'script_user_dn'       => "cn=scriptuser,ou=profile,${basedn}",
        'script_user_pass'     => $passwords::ldap::labs::script_user_pass,
        'user_id_attribute'    => 'uid',
        'tenant_id_attribute'  => 'cn',
        'ca'                   => 'ca-certificates.crt',
        'wikildapdomain'       => 'labs',
        'wikicontrollerapiurl' => 'https://wikitech.wikimedia.org/w/api.php',
        'sudobasedn'           => $sudobasedn,
        'pagesize'             => '2000',
        'nss_min_uid'          => '499',
    }
}
