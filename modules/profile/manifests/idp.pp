class profile::idp(
    Hash              $ldap_config            = lookup('ldap', Hash, hash, {}),
    String            $keystore_password      = lookup('profile::idp::keystore_password'),
    String            $key_password           = lookup('profile::idp::key_password'),
    String            $tgc_signing_key        = lookup('profile::idp::tgc_signing_key'),
    String            $tgc_encryption_key     = lookup('profile::idp::tgc_encryption_key'),
    String            $webflow_signing_key    = lookup('profile::idp::webflow_signing_key'),
    String            $webflow_encryption_key = lookup('profile::idp::webflow_encryption_key'),
    String            $u2f_signing_key        = lookup('profile::idp::u2f_signing_key'),
    String            $u2f_encryption_key     = lookup('profile::idp::u2f_encryption_key'),
    String            $totp_signing_key       = lookup('profile::idp::totp_signing_key'),
    String            $totp_encryption_key    = lookup('profile::idp::totp_encryption_key'),
    Hash[String,Hash] $services               = lookup('profile::idp::services'),
    Array[String[1]]  $ldap_attribute_list    = lookup('profile::idp::ldap_attributes'),
){

    include passwords::ldap::production
    class{ 'sslcert::dhparam': }
    tlsproxy::localssl {'idp':
        upstream_ports  => ['8080'],
        default_server  => true,
        acme_chief      => true,
        ssl_ecdhe_curve => false,
    }

    ferm::service {'cas-https':
        proto => 'tcp',
        port  => 443,
    }

    $groovy_source = 'puppet:///modules/profile/idp/global_principal_attribute_predicate.groovy'
    class { 'apereo_cas':
        server_name            => 'https://idp.wikimedia.org',
        server_prefix          => '/',
        server_port            => 8080,
        server_enable_ssl      => false,
        tomcat_proxy           => true,
        groovy_source          => $groovy_source,
        keystore_content       => wmflib::secret('casserver/thekeystore', true),
        keystore_password      => $keystore_password,
        key_password           => $key_password,
        tgc_signing_key        => $tgc_signing_key,
        tgc_encryption_key     => $tgc_encryption_key,
        webflow_signing_key    => $webflow_signing_key,
        webflow_encryption_key => $webflow_encryption_key,
        u2f_signing_key        => $u2f_signing_key,
        u2f_encryption_key     => $u2f_encryption_key,
        totp_signing_key       => $totp_signing_key,
        totp_encryption_key    => $totp_encryption_key,
        ldap_start_tls         => false,
        ldap_uris              => ["ldaps://${ldap_config[ro-server]}:636",
                                    "ldaps://${ldap_config[ro-server-fallback]}:636",],
        ldap_base_dn           => $ldap_config['base-dn'],
        ldap_attribute_list    => $ldap_attribute_list,
        log_level              => 'DEBUG',
        ldap_bind_pass         => $passwords::ldap::production::proxypass,
        ldap_bind_dn           => "cn=proxyagent,ou=profile,${ldap_config['base-dn']}",
        services               => $services,
    }
}
