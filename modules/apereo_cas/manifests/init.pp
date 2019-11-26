#
class apereo_cas (
    Optional[String[1]]          $tgc_signing_key        = undef,
    Optional[String[1]]          $tgc_encryption_key     = undef,
    Optional[String[1]]          $webflow_signing_key    = undef,
    Optional[String[1]]          $webflow_encryption_key = undef,
    Boolean                      $enable_u2f             = true,
    Optional[String[1]]          $u2f_signing_key        = undef,
    Optional[String[1]]          $u2f_encryption_key     = undef,
    Boolean                      $enable_totp            = false,
    Optional[String[1]]          $totp_signing_key       = undef,
    Optional[String[1]]          $totp_encryption_key    = undef,
    Optional[Stdlib::Filesource] $keystore_source        = undef,
    Optional[String[1]]          $keystore_content       = undef,
    Optional[Stdlib::Filesource] $groovy_source          = undef,
    Stdlib::Unixpath             $overlay_dir            = '/srv/cas/overlay-template',
    Stdlib::Unixpath             $devices_dir            = '/srv/cas/devices',
    Stdlib::Unixpath             $base_dir               = '/etc/cas',
    Stdlib::Unixpath             $log_dir                = '/var/log/cas',
    Stdlib::Unixpath             $tomcat_basedir         = "${log_dir}/tomcat",
    Stdlib::Unixpath             $u2f_devices_path       = "${devices_dir}/u2fdevices.json",
    Stdlib::Unixpath             $totp_devices_path      = "${devices_dir}/totpdevices.json",
    Stdlib::Unixpath             $keystore_path          = "${base_dir}/thekeystore",
    String[1]                    $keystore_password      = 'changeit',
    String[1]                    $key_password           = 'changeit',
    String                       $overlay_repo           = 'operations/software/cas-overlay-template',
    Stdlib::HTTPSUrl             $server_name            = "https://${facts['fqdn']}:8443",
    Stdlib::Port                 $server_port            = 8443,
    Stdlib::Unixpath             $server_prefix          = '/cas',
    Boolean                      $enable_prometheus      = false,
    Boolean                      $server_enable_ssl      = true,
    Boolean                      $tomcat_proxy           = false,
    Array[String[1]]             $ldap_attribute_list    = ['cn', 'memberOf', 'mail'],
    Array[Apereo_cas::LDAPUri]   $ldap_uris              = [],
    Apereo_cas::Ldapauth         $ldap_auth              = 'AUTHENTICATED',
    Apereo_cas::Ldapconnection   $ldap_connection        = 'ACTIVE_PASSIVE',
    Boolean                      $ldap_start_tls         = true,
    String                       $ldap_base_dn           = 'dc=example,dc=org',
    String                       $ldap_search_filter     = 'cn={user}',
    String                       $ldap_bind_dn           = 'cn=user,dc=example,dc=org',
    String                       $ldap_bind_pass         = 'changeme',
    Apereo_cas::LogLevel         $log_level              = 'WARN',
    String                       $mfa_attribute_trigger  = 'memberOf',
    Array[String[1]]             $mfa_attribut_value     = ['mfa'],
    String                       $daemon_user            = 'cas',
    Hash[String, Hash]           $services               = {},
    Optional[Stdlib::Fqdn]       $idp_primary            = undef,
    Optional[Stdlib::Fqdn]       $idp_failover           = undef,
) {
    if $keystore_source == undef and $keystore_content == undef {
        error('you must provide either $keystore_source or $keystore_content')
    }
    if $keystore_source and $keystore_content {
        error('you cannot provide $keystore_source and $keystore_content')
    }
    $config_dir = "${base_dir}/config"
    $services_dir = "${base_dir}/services"

    $is_idp_primary = $trusted['certname'] == $idp_primary

    if $is_idp_primary {
        $ensure_rsync = 'present'
    } else {
        $ensure_rsync = 'absent'
    }

    if $idp_primary and $idp_failover {
        rsync::server::module { 'u2f_devices':
            ensure         => $ensure_rsync,
            path           => $devices_dir,
            read_only      => 'yes',
            hosts_allow    => [$idp_failover],
            auto_ferm      => true,
            auto_ferm_ipv6 => true,
        }
    }

    ensure_packages(['openjdk-11-jdk'])
    user{$daemon_user:
        ensure   => present,
        comment  => 'apereo cas user',
        home     => $tomcat_basedir,
        shell    => '/usr/sbin/nologin',
        password => '!',
        system   => true,
    }
    $groovy_file = '/etc/cas/global_principal_attribute_predicate.groovy'
    if $groovy_source {
        file{$groovy_file:
            source => $groovy_source,
        }
    }
    file {wmflib::dirtree($overlay_dir) + [$services_dir, $config_dir, $overlay_dir]:
        ensure => directory,
    }
    file{[$devices_dir, $base_dir, $log_dir]:
        ensure  => directory,
        owner   => $daemon_user,
        mode    => '0600',
        recurse => true,
    }
    git::clone {$overlay_repo:
        ensure    => 'latest',
        directory => $overlay_dir,
    }
    file {"${config_dir}/cas.properties":
        ensure  => file,
        owner   => $daemon_user,
        group   => 'root',
        mode    => '0400',
        content => template('apereo_cas/cas.properties.erb'),
        before  => Systemd::Service['cas'],
        notify  => Service['cas'],
    }
    file {"${config_dir}/log4j2.xml":
        ensure  => file,
        owner   => $daemon_user,
        group   => 'root',
        mode    => '0400',
        content => template('apereo_cas/log4j2.xml.erb'),
        before  => Systemd::Service['cas'],
        notify  => Service['cas'],
    }
    file {$keystore_path:
        ensure  => file,
        owner   => $daemon_user,
        group   => 'root',
        mode    => '0400',
        content => $keystore_content,
        source  => $keystore_source,
        before  => Systemd::Service['cas'],
        notify  => Service['cas'],
    }
    exec{'build cas war':
        command => "${overlay_dir}/build.sh package",
        creates => "${overlay_dir}/build/libs/cas.war",
        cwd     => $overlay_dir,
        require => Git::Clone[$overlay_repo]
    }
    exec{'update cas war':
        command     => "${overlay_dir}/build.sh update",
        cwd         => $overlay_dir,
        require     => Exec['build cas war' ],
        subscribe   => Git::Clone[$overlay_repo],
        notify      => Service['cas'],
        refreshonly => true,
    }
    systemd::service {'cas':
        content => template('apereo_cas/cas.service.erb'),
        require => Exec['build cas war' ],
    }
    $services.each |String $service, Hash $config| {
        apereo_cas::service {$service:
            notify => Service['cas'],
            *      => $config
        }
    }
}
