class profile::idp(
    Hash   $ldap_config            = lookup('ldap', Hash, hash, {}),
    String $keystore_password      = lookup('profile::idp::keystore_password'),
    String $key_password           = lookup('profile::idp::key_password'),
    String $tgc_signing_key        = lookup('profile::idp::tgc_signing_key'),
    String $tgc_encryption_key     = lookup('profile::idp::tgc_encryption_key'),
    String $webflow_signing_key    = lookup('profile::idp::webflow_signing_key'),
    String $webflow_encryption_key = lookup('profile::idp::webflow_encryption_key'),
    String $u2f_signing_key        = lookup('profile::idp::u2f_signing_key'),
    String $u2f_encryption_key     = lookup('profile::idp::u2f_encryption_key'),
    String $gauth_signing_key      = lookup('profile::idp::gauth_signing_key'),
    String $gauth_encryption_key   = lookup('profile::idp::gauth_encryption_key'),
){

    include passwords::ldap::production

    class { 'apereo_cas':
        server_name            => 'https://idp.wikimedia.org:8443',
        server_prefix          => 'https://idp.wikimedia.org:8443/cas',
        keystore_content       => secret('casserver/thekeystore'),
        keystore_password      => $keystore_password,
        key_password           => $key_password,
        tgc_signing_key        => $tgc_signing_key,
        tgc_encryption_key     => $tgc_encryption_key,
        webflow_signing_key    => $webflow_signing_key,
        webflow_encryption_key => $webflow_encryption_key,
        u2f_signing_key        => $u2f_signing_key,
        u2f_encryption_key     => $u2f_encryption_key,
        gauth_signing_key      => $gauth_signing_key,
        gauth_encryption_key   => $gauth_encryption_key,
        ldap_start_tls         => false,
        ldap_uris              => ["ldaps://${ldap_config[ro-server]}:636",
                                    "ldaps://${ldap_config[ro-server-fallback]}:636",],
        ldap_base_dn           => $ldap_config['base-dn'],
        log_level              => 'DEBUG',
        ldap_bind_pass         => $passwords::ldap::production::proxypass,
        ldap_bind_dn           => "cn=proxyagent,ou=profile,${ldap_config['base-dn']}",
    }
}
