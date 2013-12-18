class ldap::role::config::labs {
    include passwords::ldap::labs

    $basedn = 'dc=wikimedia,dc=org'
    $servernames = $site ? {
        'pmtpa' => [ 'virt0.wikimedia.org', 'virt1000.wikimedia.org' ],
        'eqiad' => [ 'virt1000.wikimedia.org', 'virt0.wikimedia.org' ]
    }
    $sudobasedn = $realm ? {
        'labs'       => "ou=sudoers,cn=${instanceproject},ou=projects,${basedn}",
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
        'ca'                   => 'Equifax_Secure_CA.pem',
        'wikildapdomain'       => 'labs',
        'wikicontrollerapiurl' => 'https://wikitech.wikimedia.org/w/api.php',
        'sudobasedn'           => $sudobasedn,
        'pagesize'             => '2000',
        'nss_min_uid'          => '499',
    }
}

# TODO: kill this role at some point
class ldap::role::config::production {
    include passwords::ldap::production

    $basedn = 'dc=wikimedia,dc=org'
    $servernames = $site ? {
        'pmtpa' => [ 'nfs1.pmtpa.wmnet', 'nfs2.pmtpa.wmnet' ],
        'eqiad' => [ 'nfs2.pmtpa.wmnet', 'nfs1.pmtpa.wmnet' ],
    }
    $sudobasedn = "ou=sudoers,${basedn}"
    $ldapconfig = {
        'servernames'          => $servernames,
        'basedn'               => $basedn,
        'groups_rdn'           => 'ou=groups',
        'users_rdn'            => 'ou=people',
        'domain'               => 'wikimedia',
        'proxyagent'           => "cn=proxyagent,ou=profile,${basedn}",
        'proxypass'            => $passwords::ldap::production::proxypass,
        'writer_dn'            => "uid=novaadmin,ou=people,${basedn}",
        'writer_pass'          => $passwords::ldap::production::writerpass,
        'script_user_dn'       => "cn=scriptuser,ou=profile,${basedn}",
        'script_user_pass'     => $passwords::ldap::labs::script_user_pass,
        'user_id_attribute'    => 'uid',
        'tenant_id_attribute'  => 'cn',
        'ca'                   => 'wmf-ca.pem',
        'wikildapdomain'       => 'labs',
        'wikicontrollerapiurl' => 'https://wikitech.wikimedia.org/w/api.php',
        'sudobasedn'           => $sudobasedn,
        'pagesize'             => '2000',
        'nss_min_uid'          => '499',
    }
}

class ldap::role::config::corp {
    include passwords::ldap::corp

    $basedn = 'dc=corp,dc=wikimedia,dc=org'
    $servernames = [ 'sanger.wikimedia.org', 'sfo-aaa1.corp.wikimedia.org' ]
    $sudobasedn = "ou=sudoers,${basedn}"
    $ldapconfig = {
        'servernames'         => $servernames,
        'basedn'              => $basedn,
        'groups_rdn'          => 'ou=groups',
        'users_rdn'           => 'ou=people',
        'domain'              => 'corp',
        'proxyagent'          => "cn=proxyagent,ou=profile,${basedn}",
        'proxypass'           => $passwords::ldap::corp::proxypass,
        'writer_dn'           => "uid=novaadmin,ou=people,${basedn}",
        'writer_pass'         => $passwords::ldap::corp::writerpass,
        'script_user'         => '',
        'script_user_pass'    => '',
        'user_id_attribute'   => 'uid',
        'tenant_id_attribute' => 'cn',
        'ca'                  => 'wmf-ca.pem',
        'sudobasedn'          => $sudobasedn,
        'pagesize'            => '1000',
        'nss_min_uid'         => '499',
    }
}
