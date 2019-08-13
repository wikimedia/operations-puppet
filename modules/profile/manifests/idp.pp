class profile::idp(
    Hash $ldap_config = lookup('ldap', Hash, hash, {}),
){

    $ldap_base = $ldap_config['base-dn']
    include passwords::ldap::production

    class { 'apereo_cas':
        server_name         => 'https://idp.wikimedia.org:8443',
        server_prefix       => 'https://idp.wikimedia.org:8443/cas',
        keystore_content    => secret('casserver/thekeystore'),
        ldap_uris           => ["ldaps://${ldap_config[ro-server]}:636",
                                "ldaps://${ldap_config[ro-server-fallback]}:636",
                                ],
        ldap_base_dn        => $::ldap_base,
        log_level           => 'DEBUG',
        ldap_bind_pass      => $passwords::ldap::production::proxypass,
        ldap_bind_dn        => "cn=proxyagent,ou=profile,${::ldap_base}",
        ldap_search_filter  => '(objectClass=posixAccount)',
        ldap_attribute_list => ['cn', 'memberOf', 'mail'],
    }
}
