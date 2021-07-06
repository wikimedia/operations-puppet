#
class apereo_cas (
    Array[Stdlib::Fqdn]               $idp_nodes,
    Optional[String[1]]               $tgc_signing_key               = undef,
    Optional[String[1]]               $tgc_encryption_key            = undef,
    Optional[String[1]]               $webflow_signing_key           = undef,
    Optional[String[1]]               $webflow_encryption_key        = undef,
    Boolean                           $enable_u2f                    = true,
    Optional[String[1]]               $u2f_signing_key               = undef,
    Optional[String[1]]               $u2f_encryption_key            = undef,
    Boolean                           $enable_totp                   = false,
    Optional[String[1]]               $totp_signing_key              = undef,
    Optional[String[1]]               $totp_encryption_key           = undef,
    Optional[Stdlib::Filesource]      $keystore_source               = undef,
    Optional[String[1]]               $keystore_content              = undef,
    Integer[60,604800]                $max_session_length            = 604800,
    Integer[60,604800]                $max_rememberme_session_length = $max_session_length,
    Integer[60,86400]                 $session_inactivity_timeout    = 3600,
    Optional[Stdlib::Filesource]      $groovy_source                 = undef,
    Optional[Array[Stdlib::Host]]     $prometheus_nodes              = [],
    Optional[Array[String]]           $actuators                     = [],
    Stdlib::Unixpath                  $base_dir                      = '/etc/cas',
    Stdlib::Unixpath                  $log_dir                       = '/var/log/cas',
    Stdlib::Unixpath                  $tomcat_basedir                = "${log_dir}/tomcat",
    Stdlib::Unixpath                  $keystore_path                 = "${base_dir}/thekeystore",
    String[1]                         $keystore_password             = 'changeit',
    String[1]                         $key_password                  = 'changeit',
    Stdlib::HTTPSUrl                  $server_name                   = "https://${facts['fqdn']}:8443",
    Stdlib::Port                      $server_port                   = 8443,
    Stdlib::Unixpath                  $server_prefix                 = '/cas',
    Boolean                           $server_enable_ssl             = true,
    Boolean                           $tomcat_proxy                  = false,
    Array[String[1]]                  $ldap_attribute_list           = ['cn', 'memberOf', 'mail'],
    Array[Apereo_cas::LDAPUri]        $ldap_uris                     = [],
    Apereo_cas::Ldapauth              $ldap_auth                     = 'AUTHENTICATED',
    Apereo_cas::Ldapconnection        $ldap_connection               = 'ACTIVE_PASSIVE',
    Boolean                           $ldap_start_tls                = true,
    String                            $ldap_base_dn                  = 'dc=example,dc=org',
    String                            $ldap_group_cn                 = 'ou=groups',
    String                            $ldap_search_filter            = 'cn={user}',
    String                            $ldap_bind_dn                  = 'cn=user,dc=example,dc=org',
    String                            $ldap_bind_pass                = 'changeme',
    Apereo_cas::LogLevel              $log_level                     = 'WARN',
    String                            $mfa_attribute_trigger         = 'memberOf',
    Array[String[1]]                  $mfa_attribut_value            = ['mfa'],
    String                            $daemon_user                   = 'cas',
    Hash[String, Hash]                $services                      = {},
    Optional[String[1]]               $java_opts                     = undef,
    Boolean                           $memcached_enable              = false,
    Stdlib::Port                      $memcached_port                = 11211,
    Stdlib::Host                      $memcached_server              = 'localhost',
    Apereo_cas::Memcached::Transcoder $memcached_transcoder          = 'KRYO',
    Boolean                           $u2f_jpa_enable                = false,
    String                            $u2f_jpa_username              = 'cas',
    String                            $u2f_jpa_password              = 'changeme',
    String                            $u2f_jpa_server                = '127.0.0.1',
    String                            $u2f_jpa_db                    = 'cas',
    Optional[Integer]                 $u2f_token_expiry_days         = undef,
    Boolean                           $enable_cors                   = false,
    Boolean                           $cors_allow_credentials        = false,
    Array[Stdlib::HTTPSUrl]           $cors_allowed_origins          = [],
    Array[String]                     $cors_allowed_headers          = [],
    # TODO: switch to Stdlib::Http::Method
    # https://github.com/puppetlabs/puppetlabs-stdlib/pull/1192
    Array[Wmflib::HTTP::Method]       $cors_allowed_methods          = ['GET'],
) {
    if $keystore_source == undef and $keystore_content == undef and $server_enable_ssl {
        fail('you must provide either $keystore_source or $keystore_content')
    }
    if $keystore_source and $keystore_content {
        fail('you cannot provide $keystore_source and $keystore_content')
    }
    $config_dir = "${base_dir}/config"
    $services_dir = "${base_dir}/services"

    ensure_packages(['cas', 'python3-memcache'])

    systemd::unit{'tomcat9':
        override => true,
        restart  => true,
        content  => "[Service]\nReadWritePaths=${log_dir}\n",
    }

    $groovy_file = '/etc/cas/global_principal_attribute_predicate.groovy'
    if $groovy_source {
        file{$groovy_file:
            source => $groovy_source,
        }
    }
    file{$config_dir:
        ensure => directory,
    }
    file{$services_dir:
        ensure  => directory,
        recurse => true,
        purge   => true,
    }
    file{[$base_dir, $log_dir]:
        ensure  => directory,
        owner   => $daemon_user,
        mode    => '0600',
        recurse => true,
    }
    file {"${config_dir}/cas.properties":
        ensure  => file,
        owner   => $daemon_user,
        group   => 'root',
        mode    => '0400',
        content => template('apereo_cas/cas.properties.erb'),
    }
    file {"${config_dir}/log4j2.xml":
        ensure  => file,
        owner   => $daemon_user,
        group   => 'root',
        mode    => '0400',
        content => template('apereo_cas/log4j2.xml.erb'),
    }
    $keystore_ensure = $server_enable_ssl ? {
        true    => file,
        default => absent,
    }
    file {$keystore_path:
        ensure  => $keystore_ensure,
        owner   => $daemon_user,
        group   => 'root',
        mode    => '0400',
        content => $keystore_content,
        source  => $keystore_source,
    }

    file { '/usr/local/sbin/memcached-dump':
        ensure => present,
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/apereo_cas/memcached-dump.py',
    }

    file { '/usr/local/sbin/return-tgt-for-user':
        ensure => present,
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/apereo_cas/return-tgt-for-user.py',
    }

    $services.each |String $service, Hash $config| {
        apereo_cas::service {$service:
            * => $config
        }
    }
}
