# @summary profile to configure the idp
# @param ldap_config a hash containing the ldap configeration
class profile::idp(
    Array[Stdlib::Host]         $prometheus_nodes       = lookup('prometheus_nodes'),
    Hash                        $ldap_config            = lookup('ldap', Hash, hash, {}),
    Enum['ldaps', 'starttls']   $ldap_encryption        = lookup('profile::idp::ldap_encryption'),
    String                      $keystore_password      = lookup('profile::idp::keystore_password'),
    String                      $key_password           = lookup('profile::idp::key_password'),
    String                      $tgc_signing_key        = lookup('profile::idp::tgc_signing_key'),
    String                      $tgc_encryption_key     = lookup('profile::idp::tgc_encryption_key'),
    String                      $webflow_signing_key    = lookup('profile::idp::webflow_signing_key'),
    String                      $webflow_encryption_key = lookup('profile::idp::webflow_encryption_key'),
    String                      $u2f_signing_key        = lookup('profile::idp::u2f_signing_key'),
    String                      $u2f_encryption_key     = lookup('profile::idp::u2f_encryption_key'),
    Integer                     $max_session_length     = lookup('profile::idp::max_session_length'),
    Hash[String,Hash]           $services               = lookup('profile::idp::services'),
    Array[String[1]]            $ldap_attribute_list    = lookup('profile::idp::ldap_attributes'),
    Array[String]               $actuators              = lookup('profile::idp::actuators'),
    Stdlib::HTTPSUrl            $server_name            = lookup('profile::idp::server_name'),
    Array[Stdlib::Fqdn]         $idp_nodes              = lookup('profile::idp::idp_nodes'),
    Boolean                     $is_staging_host        = lookup('profile::idp::is_staging_host'),
    Boolean                     $memcached_enable       = lookup('profile::idp::memcached_enable'),
    Boolean                     $u2f_jpa_enable         = lookup('profile::idp::u2f_jpa_enable'),
    String                      $u2f_jpa_username       = lookup('profile::idp::u2f_jpa_username'),
    String                      $u2f_jpa_password       = lookup('profile::idp::u2f_jpa_password'),
    Stdlib::Host                $u2f_jpa_server         = lookup('profile::idp::u2f_jpa_server'),
    String                      $u2f_jpa_db             = lookup('profile::idp::u2f_jpa_db'),
    Boolean                     $enable_cors            = lookup('profile::idp::enable_cors'),
    Boolean                     $cors_allow_credentials = lookup('profile::idp::cors_allow_credentials'),
    Array[Stdlib::HTTPSUrl]     $cors_allowed_origins   = lookup('profile::idp::cors_allowed_origins'),
    Array[String]               $cors_allowed_headers   = lookup('profile::idp::cors_allowed_headers'),
    Array[Wmflib::HTTP::Method] $cors_allowed_methods   = lookup('profile::idp::cors_allowed_methods'),
    Optional[Integer]           $u2f_token_expiry_days  = lookup('profile::idp::u2f_token_expiry_days'),
    Boolean                     $envoy_termination      = lookup('profile:idp::envoy_termination'),
){

    include passwords::ldap::production
    class{ 'sslcert::dhparam': }
    if $envoy_termination {
      include profile::tlsproxy::envoy
      $ferm_port = 443
    } else {
      # In cloud we use the shared wmfcloud proxy for tls termination
      $ferm_port = 8080
    }

    class {'tomcat': }

    $jmx_port = 9200
    $jmx_config = '/etc/prometheus/cas_jmx_exporter.yaml'
    $jmx_jar = '/usr/share/java/prometheus/jmx_prometheus_javaagent.jar'
    $java_opts = "-javaagent:${jmx_jar}=${facts['networking']['ip']}:${jmx_port}:${jmx_config}"
    $groovy_source = 'puppet:///modules/profile/idp/global_principal_attribute_predicate.groovy'
    $log_dir = '/var/log/cas'

    $cas_daemon_user = 'tomcat'

    if $is_staging_host {
        apt::repository{ 'component-idp-test':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/idp-test',
        }
    }

    if $ldap_encryption == 'starttls' {
      $ldap_schema    = 'ldap'
      $ldap_start_tls = true
      $ldap_port      = 389
    } else {
      $ldap_schema    = 'ldaps'
      $ldap_start_tls = false
      $ldap_port      = 636
    }
    $ldap_uris = ["${ldap_schema}://${ldap_config[ro-server]}:${ldap_port}",
                  "${ldap_schema}://${ldap_config[ro-server-fallback]}:${ldap_port}"]
    class { 'apereo_cas':
        server_name            => $server_name,
        server_prefix          => '/',
        server_port            => 8080,
        server_enable_ssl      => false,
        tomcat_proxy           => true,
        groovy_source          => $groovy_source,
        prometheus_nodes       => $prometheus_nodes,
        keystore_content       => secret('casserver/thekeystore'),
        keystore_password      => $keystore_password,
        key_password           => $key_password,
        tgc_signing_key        => $tgc_signing_key,
        tgc_encryption_key     => $tgc_encryption_key,
        webflow_signing_key    => $webflow_signing_key,
        webflow_encryption_key => $webflow_encryption_key,
        u2f_signing_key        => $u2f_signing_key,
        u2f_encryption_key     => $u2f_encryption_key,
        ldap_start_tls         => $ldap_start_tls,
        ldap_uris              => $ldap_uris,
        ldap_base_dn           => $ldap_config['base-dn'],
        ldap_group_cn          => $ldap_config['group_cn'],
        ldap_attribute_list    => $ldap_attribute_list,
        log_level              => 'DEBUG',
        ldap_bind_pass         => $passwords::ldap::production::proxypass,
        ldap_bind_dn           => "cn=proxyagent,ou=profile,${ldap_config['base-dn']}",
        services               => $services,
        idp_nodes              => $idp_nodes,
        java_opts              => $java_opts,
        max_session_length     => $max_session_length,
        actuators              => $actuators,
        daemon_user            => $cas_daemon_user,
        log_dir                => $log_dir,
        memcached_enable       => $memcached_enable,
        memcached_port         => 11213,  # we use mcrouter which is on this port
        u2f_jpa_enable         => $u2f_jpa_enable,
        u2f_jpa_username       => $u2f_jpa_username,
        u2f_jpa_password       => $u2f_jpa_password,
        u2f_jpa_server         => $u2f_jpa_server,
        u2f_jpa_db             => $u2f_jpa_db,
        u2f_token_expiry_days  => $u2f_token_expiry_days,
        enable_cors            => $enable_cors,
        cors_allow_credentials => $cors_allow_credentials,
        cors_allowed_origins   => $cors_allowed_origins,
        cors_allowed_headers   => $cors_allowed_headers,
        cors_allowed_methods   => $cors_allowed_methods,
    }

    ferm::service {'cas-https':
        proto => 'tcp',
        port  => $ferm_port,
    }

    profile::prometheus::jmx_exporter{ "idp_${facts['networking']['hostname']}":
        hostname         => $facts['networking']['hostname'],
        port             => $jmx_port,
        prometheus_nodes => $prometheus_nodes,
        config_dir       => $jmx_config.dirname,
        config_file      => $jmx_config,
        content          => file('profile/idp/cas_jmx_exporter.yaml'),
    }
    if $memcached_enable {
        class {'profile::idp::memcached':
            idp_nodes => $idp_nodes,
        }
    }

}
