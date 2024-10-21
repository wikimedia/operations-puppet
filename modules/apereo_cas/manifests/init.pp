# SPDX-License-Identifier: Apache-2.0
# @summary Class to configure Apero CAS
# @param idp_nodes list of idp nodes
# @param tgc_signing_key the tgc signing key
# @param tgc_encryption_key the tgc encyption key
# @param tgc_cookie_same_site set the SameSite policy for the TGC cookie
# @param tgc_cookie_pin_to_session If true the TGC cookie is pined to the users IP address and user agent
# @param webflow_signing_key the webflow signing key
# @param webflow_encryption_key the webflow encyption key
# @param enable_u2f If to enable u2f
# @param u2f_signing_key the utf signing key
# @param u2f_encryption_key the utf encyption key
# @param web_authn_signing_key the utf signing key
# @param web_authn_encryption_key the utf encyption key
# @param oauth_crypto_signing_key the utf signing key
# @param oauth_crypto_encryption_key the utf encyption key
# @param oauth_token_signing_key the utf signing key
# @param oauth_token_encryption_key the utf encyption key
# @param spring_username spring.security.user.name
# @param spring_password spring.security.user.password
# @param keystore_source the keystore source location.  only one of keystore_source and keystore_content can be presetn
# @param keystore_content the keystore content.  only one of keystore_source and keystore_content can be presetn
# @param max_session_length maximum session length in seconds. https://wikitech.wikimedia.org/wiki/CAS-SSO/Administration#Session_timeout_handling
# @param max_rememberme_session_length maximum rember me session length: https://wikitech.wikimedia.org/wiki/CAS-SSO/Administration#Session_timeout_handling
# @param session_inactivity_timeout session inactivity time out https://wikitech.wikimedia.org/wiki/CAS-SSO/Administration#Session_timeout_handling
# @param groovy_source source of groovy authentication script
# @param prometheus_nodes list of preometheus nodes
# @param actuators list of actuators
# @param base_dir base directory for config
# @param log_dir logging directory
# @param tomcat_basedir tomecat base directory
# @param keystore_path path to store the keystore
# @param keystore_password keystore password
# @param key_password key password
# @param server_name the location of the idp site
# @param server_port port cas will listen on
# @param server_prefix URL path cas app will be deployed to
# @param server_enable_ssl if ssl is enabled
# @param tomcat_proxy if using external tomecat proxy
# @param enable_ldap configure cas to authenticate agains ldap
# @param ldap_attribute_list list of ldap attributes to fetch
# @param ldap_uris list of ldap uris to use for authentication
# @param ldap_auth ldap authentication method to use
# @param ldap_connection ldap connection type to maintain
# @param ldap_start_tls use STARTLS for ldap connections
# @param ldap_base_dn ldap base dn
# @param ldap_group_cn ldap groups cn
# @param ldap_search_filter ldap filter to use when searching useres
# @param ldap_bind_dn bind dn to use to search ldap
# @param ldap_bind_pass bind password to use to search ldap
# @param log_level log level to configure
# @param daemon_user system useres used to run the daemon
# @param services list of trusted services
# @param java_opts java options
# @param memcached_enable if we should use memcached
# @param memcached_port memcached port
# @param memcached_server memcached address
# @param memcached_transcoder memcached encoder to use
# @param u2f_jpa_enable use JPA for utf token storage
# @param u2f_jpa_username u2f JPA username
# @param u2f_jpa_password u2f JPA password
# @param u2f_jpa_server u2f JPA server
# @param u2f_jpa_db u2f JPA database name
# @param u2f_token_expiry_days number of days of inactivity before u2f tokens are automatically removed
# @param enable_cors Enable CORS protection
# @param cors_allow_credentials if we shuold allow authentication credentials with CORS
# @param cors_allowed_origins list of origins allowed to use CORS
# @param cors_allowed_headers list of headers allowed to in CORS requests
# @param cors_allowed_methods list of methods allowed with CORS
# @param delegated_authenticators list of delegated authenticators
# @param oidc_issuers_pattern defines the regular expression pattern that is
#        matched against the calculated issuer from the request.
# @param oidc_id_token_claims weather to support id token claims
# @param enable_webauthn Whether to enable WebAuthN support or not
# @param webauthn_relaying_party The relying party ID to be used for WebAuthN
class apereo_cas (
    Array[Stdlib::Fqdn]               $idp_nodes,
    Optional[String[1]]               $tgc_signing_key               = undef,
    Optional[String[1]]               $tgc_encryption_key            = undef,
    Wmflib::HTTP::SameSite            $tgc_cookie_same_site          = 'none',
    Boolean                           $tgc_cookie_pin_to_session     = true,
    Optional[String[1]]               $webflow_signing_key           = undef,
    Optional[String[1]]               $webflow_encryption_key        = undef,
    Boolean                           $enable_u2f                    = true,
    Optional[String[1]]               $u2f_signing_key               = undef,
    Optional[String[1]]               $u2f_encryption_key            = undef,
    Optional[String[1]]               $web_authn_signing_key         = undef,
    Optional[String[1]]               $web_authn_encryption_key      = undef,
    Optional[String[1]]               $oauth_crypto_signing_key      = undef,
    Optional[String[1]]               $oauth_crypto_encryption_key   = undef,
    Optional[String[1]]               $oauth_token_signing_key       = undef,
    Optional[String[1]]               $oauth_token_encryption_key    = undef,
    Optional[String[1]]               $oauth_session_encryption_key  = undef,
    Optional[String[1]]               $oauth_session_signing_key     = undef,
    Optional[String[1]]               $authn_pac4j_encryption_key    = undef,
    Optional[String[1]]               $authn_pac4j_signing_key       = undef,
    String[1]                         $spring_username               = 'casuser',
    Optional[String[1]]               $spring_password               = undef,
    Optional[Stdlib::Filesource]      $keystore_source               = undef,
    Optional[Binary]                  $keystore_content              = undef,
    Integer[60,604800]                $max_session_length            = 604800,
    Integer[60,604800]                $max_rememberme_session_length = $max_session_length,
    Integer[60,86400]                 $session_inactivity_timeout    = 3600,
    Optional[Stdlib::Filesource]      $groovy_source                 = undef,
    Array[Stdlib::Host]               $prometheus_nodes              = [],
    Array[String]                     $actuators                     = [],
    Stdlib::Unixpath                  $base_dir                      = '/etc/cas',
    Stdlib::Unixpath                  $log_dir                       = '/var/log/cas',
    Stdlib::Unixpath                  $tomcat_basedir                = "${log_dir}/tomcat",
    Stdlib::Unixpath                  $keystore_path                 = "${base_dir}/thekeystore",
    String[1]                         $keystore_password             = 'changeit',
    String[1]                         $key_password                  = 'changeit',
    Stdlib::HTTPSUrl                  $server_name                   = "https://${facts['networking']['fqdn']}:8443",
    Stdlib::Port                      $server_port                   = 8443,
    Stdlib::Unixpath                  $server_prefix                 = '/cas',
    Boolean                           $server_enable_ssl             = true,
    Boolean                           $tomcat_proxy                  = false,
    Boolean                           $enable_ldap                   = true,
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
    Wmflib::Syslog::Level::Log4j      $log_level                     = 'WARN',
    String                            $daemon_user                   = 'cas',
    Hash[String, Hash]                $services                      = {},
    Optional[String[1]]               $java_opts                     = undef,
    Boolean                           $memcached_enable              = false,
    Stdlib::Port                      $memcached_port                = 11211,
    Stdlib::Host                      $memcached_server              = 'localhost',
    Apereo_cas::Memcached::Transcoder $memcached_transcoder          = 'KRYO',
    Boolean                           $redis_enable                  = false,
    Stdlib::Port                      $redis_port                    = 6379,
    Stdlib::Host                      $redis_server                  = 'localhost',
    Boolean                           $u2f_jpa_enable                = false,
    String                            $u2f_jpa_username              = 'cas',
    String                            $u2f_jpa_password              = 'changeme',
    String                            $u2f_jpa_server                = '127.0.0.1',
    String                            $u2f_jpa_db                    = 'cas',
    Optional[Integer]                 $u2f_token_expiry_days         = undef,
    String                            $oidc_issuers_pattern          = 'a^',
    Boolean                           $oidc_id_token_claims          = false,
    Boolean                           $enable_cors                   = false,
    Boolean                           $cors_allow_credentials        = false,
    Array[Stdlib::HTTPSUrl]           $cors_allowed_origins          = [],
    Array[String]                     $cors_allowed_headers          = [],
    # TODO: switch to Stdlib::Http::Method
    # https://github.com/puppetlabs/puppetlabs-stdlib/pull/1192
    Array[Wmflib::HTTP::Method]       $cors_allowed_methods          = ['GET'],
    Array[Apereo_cas::Delegate]       $delegated_authenticators      = [],
    Boolean                           $enable_webauthn               = false,
    Stdlib::Fqdn                      $webauthn_relaying_party       = 'example.org',
    String                            $tomcat_version                = 'tomcat10',
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

    $groovy_file = '/etc/cas/global_principal_attribute_predicate.groovy'
    if $groovy_source {
        file { $groovy_file:
            source => $groovy_source,
        }
    }
    file { $config_dir:
        ensure => directory,
        owner  => $daemon_user,
    }
    file { $services_dir:
        ensure  => directory,
        recurse => true,
        purge   => true,
    }
    file { [$base_dir, $log_dir]:
        ensure => directory,
        owner  => $daemon_user,
        mode   => '0600',
    }
    $prometheus_ips = $prometheus_nodes.map |$node| { dnsquery::lookup($node) }.flatten
    $idp_ips = $idp_nodes.map |$node| { dnsquery::lookup($node) }.flatten
    file { "${config_dir}/cas.properties":
        ensure  => file,
        owner   => $daemon_user,
        group   => 'root',
        mode    => '0400',
        content => template('apereo_cas/cas.properties.erb'),
    }
    file { "${config_dir}/log4j2.xml":
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
    file { $keystore_path:
        ensure  => $keystore_ensure,
        owner   => $daemon_user,
        group   => 'root',
        mode    => '0400',
        content => $keystore_content,
        source  => $keystore_source,
    }

    # /usr/bin/memcdump is needed by memcached-dump tool
    ensure_packages('libmemcached-tools')

    file { '/usr/local/sbin/memcached-dump':
        ensure => file,
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/apereo_cas/memcached-dump.py',
    }

    file { '/usr/local/sbin/return-tgt-for-user':
        ensure => file,
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/apereo_cas/return-tgt-for-user.py',
    }
    file { '/usr/local/sbin/cas-remove-u2f':
        ensure => file,
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/apereo_cas/cas_remove_u2f.py',
    }

    $services.each |String $service, Hash $config| {
        apereo_cas::service { $service:
            * => $config,
        }
    }
}
