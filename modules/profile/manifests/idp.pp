# SPDX-License-Identifier: Apache-2.0
# @summary profile to configure the idp
# @param ldap_config a hash containing the ldap configeration
class profile::idp(
    Array[Stdlib::Host]               $prometheus_nodes            = lookup('prometheus_nodes'),
    Hash                              $ldap_config                 = lookup('ldap'),
    Wmflib::Syslog::Level::Log4j      $log_level                   = lookup('profile::idp::log_level'),
    Enum['ldaps', 'ldap']             $ldap_schema                 = lookup('profile::idp::ldap_schema'),
    Boolean                           $enable_ldap                 = lookup('profile::idp::enable_ldap'),
    Boolean                           $ldap_start_tls              = lookup('profile::idp::ldap_start_tls'),
    String                            $keystore_password           = lookup('profile::idp::keystore_password'),
    String                            $key_password                = lookup('profile::idp::key_password'),
    String                            $tgc_signing_key             = lookup('profile::idp::tgc_signing_key'),
    String                            $tgc_encryption_key          = lookup('profile::idp::tgc_encryption_key'),
    Wmflib::HTTP::SameSite            $tgc_cookie_same_site        = lookup('profile::idp::tgc_cookie_same_site'),
    Boolean                           $tgc_cookie_pin_to_session   = lookup('profile::idp::tgc_cookie_pin_to_session'),
    String                            $webflow_signing_key         = lookup('profile::idp::webflow_signing_key'),
    String                            $webflow_encryption_key      = lookup('profile::idp::webflow_encryption_key'),
    String                            $u2f_signing_key             = lookup('profile::idp::u2f_signing_key'),
    String                            $u2f_encryption_key          = lookup('profile::idp::u2f_encryption_key'),
    String                            $web_authn_signing_key       = lookup('profile::idp::web_authn_signing_key'),
    String                            $web_authn_encryption_key    = lookup('profile::idp::web_authn_encryption_key'),
    String                            $oauth_crypto_signing_key    = lookup('profile::idp::oauth_crypto_signing_key'),
    String                            $oauth_crypto_encryption_key = lookup('profile::idp::oauth_crypto_encryption_key'),
    String                            $oauth_token_signing_key     = lookup('profile::idp::oauth_token_signing_key'),
    String                            $oauth_token_encryption_key  = lookup('profile::idp::oauth_token_encryption_key'),
    String                            $oauth_session_encryption_key = lookup('profile::idp::oauth_session_encryption_key'),
    String                            $oauth_session_signing_key   = lookup('profile::idp::oauth_session_signing_key'),
    String                            $authn_pac4j_encryption_key  = lookup('profile::idp::authn_pac4j_encryption_key'),
    String                            $authn_pac4j_signing_key     = lookup('profile::idp::authn_pac4j_signing_key'),
    String                            $spring_password             = lookup('profile::idp::spring_password'),
    Integer                           $max_session_length          = lookup('profile::idp::max_session_length'),
    Hash[String,Hash]                 $services                    = lookup('profile::idp::services'),
    Array[String[1]]                  $ldap_attribute_list         = lookup('profile::idp::ldap_attributes'),
    Array[String]                     $actuators                   = lookup('profile::idp::actuators'),
    Stdlib::HTTPSUrl                  $server_name                 = lookup('profile::idp::server_name'),
    Array[Stdlib::Fqdn]               $idp_nodes                   = lookup('profile::idp::idp_nodes'),
    Boolean                           $is_staging_host             = lookup('profile::idp::is_staging_host'),
    Boolean                           $memcached_enable            = lookup('profile::idp::memcached_enable'),
    Boolean                           $memcached_install           = lookup('profile::idp::memcached_install'),
    Stdlib::Port                      $memcached_port              = lookup('profile::idp::memcached_port'),
    Apereo_cas::Memcached::Transcoder $memcached_transcoder      = lookup('profile::idp::memcached_transcoder'),
    Boolean                           $enable_u2f                = lookup('profile::idp::enable_u2f'),
    Boolean                           $u2f_jpa_enable            = lookup('profile::idp::u2f_jpa_enable'),
    String                            $u2f_jpa_username          = lookup('profile::idp::u2f_jpa_username'),
    String                            $u2f_jpa_password          = lookup('profile::idp::u2f_jpa_password'),
    Stdlib::Host                      $u2f_jpa_server            = lookup('profile::idp::u2f_jpa_server'),
    String                            $u2f_jpa_db                = lookup('profile::idp::u2f_jpa_db'),
    Boolean                           $enable_cors               = lookup('profile::idp::enable_cors'),
    Boolean                           $cors_allow_credentials    = lookup('profile::idp::cors_allow_credentials'),
    Array[Stdlib::HTTPSUrl]           $cors_allowed_origins      = lookup('profile::idp::cors_allowed_origins'),
    Array[String]                     $cors_allowed_headers      = lookup('profile::idp::cors_allowed_headers'),
    Array[Wmflib::HTTP::Method]       $cors_allowed_methods      = lookup('profile::idp::cors_allowed_methods'),
    Optional[Integer]                 $u2f_token_expiry_days     = lookup('profile::idp::u2f_token_expiry_days'),
    Boolean                           $envoy_termination         = lookup('profile::idp::envoy_termination'),
    Array[Apereo_cas::Delegate]       $delegated_authenticators  = lookup('profile::idp::delegated_authenticators'),
    Boolean                           $enable_webauthn           = lookup('profile::idp::enable_webauthn'),
    Stdlib::Fqdn                      $webauthn_relaying_party   = lookup('profile::idp::webauthn_relaying_party'),
    String                            $tomcat                    = lookup('profile::idp::tomcat_version', {'default_value' => 'tomcat10' }),
    String                            $oidc_issuers_pattern      = lookup('profile::idp::oidc_issuers_pattern'),
){

    ensure_packages(['python3-pymysql'])
    include passwords::ldap::production
    include profile::java
    class{ 'sslcert::dhparam': }
    if $envoy_termination {
      include profile::tlsproxy::envoy
      $firewall_port = 443
      profile::auto_restarts::service { 'envoyproxy': }
    } else {
      # In Cloud VPS we use the shared web proxy for tls termination
      $firewall_port = 8080
    }

    if $tomcat == 'tomcat9' {
        class { 'tomcat': }
    } else {
        class { $tomcat: }
    }

    $jmx_port = 9200
    $jmx_config = '/etc/prometheus/cas_jmx_exporter.yaml'
    $jmx_jar = '/usr/share/java/prometheus/jmx_prometheus_javaagent.jar'
    $java_opts = "-javaagent:${jmx_jar}=${facts['networking']['ip']}:${jmx_port}:${jmx_config}"
    $groovy_source = 'puppet:///modules/profile/idp/global_principal_attribute_predicate.groovy'
    $log_dir = '/var/log/cas'

    $cas_daemon_user = 'tomcat'

    $ldap_port = $ldap_schema ? {
      'ldap'  => 389,
      default => 636,
    }
    $ldap_uris = ["${ldap_schema}://${ldap_config[ro-server]}:${ldap_port}",
                  "${ldap_schema}://${ldap_config[ro-server-fallback]}:${ldap_port}"]
    class { 'apereo_cas':
        server_name                  => $server_name,
        server_prefix                => '/',
        server_port                  => 8080,
        server_enable_ssl            => false,
        tomcat_proxy                 => true,
        groovy_source                => $groovy_source,
        prometheus_nodes             => $prometheus_nodes,
        keystore_content             => wmflib::secret('casserver/thekeystore', true),
        keystore_password            => $keystore_password,
        key_password                 => $key_password,
        tgc_signing_key              => $tgc_signing_key,
        tgc_encryption_key           => $tgc_encryption_key,
        tgc_cookie_same_site         => $tgc_cookie_same_site,
        tgc_cookie_pin_to_session    => $tgc_cookie_pin_to_session,
        webflow_signing_key          => $webflow_signing_key,
        webflow_encryption_key       => $webflow_encryption_key,
        u2f_signing_key              => $u2f_signing_key,
        u2f_encryption_key           => $u2f_encryption_key,
        web_authn_signing_key        => $web_authn_signing_key,
        web_authn_encryption_key     => $web_authn_encryption_key,
        oauth_crypto_signing_key     => $oauth_crypto_signing_key,
        oauth_crypto_encryption_key  => $oauth_crypto_encryption_key,
        oauth_token_signing_key      => $oauth_token_signing_key,
        oauth_token_encryption_key   => $oauth_token_encryption_key,
        oauth_session_encryption_key => $oauth_session_encryption_key,
        oauth_session_signing_key    => $oauth_session_signing_key,
        authn_pac4j_encryption_key   => $authn_pac4j_encryption_key,
        authn_pac4j_signing_key      => $authn_pac4j_signing_key,
        spring_password              => $spring_password,
        enable_ldap                  => $enable_ldap,
        ldap_start_tls               => $ldap_start_tls,
        ldap_uris                    => $ldap_uris,
        ldap_base_dn                 => $ldap_config['base-dn'],
        ldap_group_cn                => $ldap_config['group_cn'],
        ldap_attribute_list          => $ldap_attribute_list,
        log_level                    => $log_level,
        ldap_bind_pass               => $passwords::ldap::production::proxypass,
        ldap_bind_dn                 => $ldap_config['proxyagent'],
        services                     => $services,
        idp_nodes                    => $idp_nodes,
        java_opts                    => $java_opts,
        max_session_length           => $max_session_length,
        actuators                    => $actuators,
        daemon_user                  => $cas_daemon_user,
        log_dir                      => $log_dir,
        memcached_enable             => $memcached_enable,
        memcached_port               => $memcached_port,
        memcached_transcoder         => $memcached_transcoder,
        enable_u2f                   => $enable_u2f,
        u2f_jpa_enable               => $u2f_jpa_enable,
        u2f_jpa_username             => $u2f_jpa_username,
        u2f_jpa_password             => $u2f_jpa_password,
        u2f_jpa_server               => $u2f_jpa_server,
        u2f_jpa_db                   => $u2f_jpa_db,
        u2f_token_expiry_days        => $u2f_token_expiry_days,
        enable_cors                  => $enable_cors,
        cors_allow_credentials       => $cors_allow_credentials,
        cors_allowed_origins         => $cors_allowed_origins,
        cors_allowed_headers         => $cors_allowed_headers,
        cors_allowed_methods         => $cors_allowed_methods,
        delegated_authenticators     => $delegated_authenticators,
        enable_webauthn              => $enable_webauthn,
        webauthn_relaying_party      => $webauthn_relaying_party,
        tomcat_version               => $tomcat,
        oidc_issuers_pattern         => $oidc_issuers_pattern
    }

    systemd::unit{ $tomcat:
        override => true,
        restart  => true,
        content  => "[Service]\nReadWritePaths=${apereo_cas::log_dir}\nEnvironment=JAVA_HOME=${profile::java::default_java_home}",
    }

    firewall::service {'cas-https':
        proto => 'tcp',
        port  => $firewall_port,
    }

    profile::prometheus::jmx_exporter{ "idp_${facts['networking']['hostname']}":
        hostname    => $facts['networking']['hostname'],
        port        => $jmx_port,
        config_dir  => $jmx_config.dirname,
        config_file => $jmx_config,
        content     => file('profile/idp/cas_jmx_exporter.yaml'),
    }
    if ($memcached_enable and $memcached_install) {
        class {'profile::idp::memcached':
            idp_nodes => $idp_nodes,
        }
    }
    file {'/usr/local/sbin/cas-manage-u2f':
      ensure => file,
      owner  => root,
      mode   => '0500',
      source => 'puppet:///modules/profile/idp/cas_manage_u2f.py',
    }

    profile::logoutd::script {'idp':
        source => 'puppet:///modules/apereo_cas/idp-logout.py',
    }

}
