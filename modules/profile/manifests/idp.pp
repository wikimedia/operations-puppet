class profile::idp(
    Hash   $ldap_config       = lookup('ldap', Hash, hash, {}),
    String $keystore_password = lookup('profile::idp::keystore_password'),
    String $key_password      = lookup('profile::idp::key_password'),
){

    include passwords::ldap::production

    class { 'apereo_cas':
        server_name       => 'https://idp.wikimedia.org:8443',
        server_prefix     => 'https://idp.wikimedia.org:8443/cas',
        keystore_content  => secret('casserver/thekeystore'),
        keystore_password => $keystore_password,
        key_password      => $key_password,
        ldap_uris         => ["ldaps://${ldap_config[ro-server]}:636",
                              "ldaps://${ldap_config[ro-server-fallback]}:636",],
        ldap_base_dn      => $ldap_config['base-dn'],
        log_level         => 'DEBUG',
        ldap_bind_pass    => $passwords::ldap::production::proxypass,
        ldap_bind_dn      => "cn=proxyagent,ou=profile,${ldap_config['base-dn']}",
    }
}
