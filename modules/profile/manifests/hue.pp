# == Class profile::hue
#
# Installs Hue server.
#
class profile::hue (
    Stdlib::Host $hive_server_host              = lookup('profile::hue::hive_server_host'),
    Optional[Integer] $hive_thrift_version      = lookup('profile::hue::hive_thrift_version', { 'default_value' => undef }),
    Stdlib::Host $database_host                 = lookup('profile::hue::database_host'),
    Hash $ldap_config                           = lookup('ldap'),
    String $ldap_base_dn                        = lookup('profile::hue::ldap_base_dn', { 'default_value' => 'dc=wikimedia,dc=org' }),
    String $database_engine                     = lookup('profile::hue::database_engine', { 'default_value' => 'mysql' }),
    String $database_user                       = lookup('profile::hue::database_user', { 'default_value' => 'hue' }),
    String $database_password                   = lookup('profile::hue::database_password', { 'default_value' => 'hue' }),
    Optional[String] $session_secret_key        = lookup('profile::hue::session_secret_key', { 'default_value' => undef }),
    Integer $database_port                      = lookup('profile::hue::database_port', { 'default_value' => 3306 }),
    String $database_name                       = lookup('profile::hue::database_name', { 'default_value' => 'hue' }),
    Boolean $ldap_create_users_on_login         = lookup('profile::hue::ldap_create_users_on_login', { 'default_value' => false }),
    Boolean $monitoring_enabled                 = lookup('profile::hue::monitoring_enabled', { 'default_value' => false }),
    Optional[Stdlib::Unixpath] $kerberos_keytab = lookup('profile::hue::kerberos_keytab', { 'default_value' => undef }),
    Optional[String] $kerberos_principal        = lookup('profile::hue::kerberos_principal', { 'default_value' => undef }),
    Optional[Stdlib::Unixpath] $kerberos_kinit_path = lookup('profile::hue::kerberos_kinit_path', { 'default_value' => undef }),
    Boolean $use_yarn_ssl_config                = lookup('profile::hue::use_yarn_ssl_config', { 'default_value' => false }),
    Boolean $use_hdfs_ssl_config                = lookup('profile::hue::use_hdfs_ssl_config', { 'default_value' => false }),
    Boolean $use_mapred_ssl_config              = lookup('profile::hue::use_mapred_ssl_config', { 'default_value' => false }),
    String $server_name                         = lookup('profile::hue::servername'),
    Boolean $enable_cas                         = lookup('profile::hue::enable_cas'),
    Boolean $use_hue4_settings                  = lookup('profile::hue::use_hue4_settings', { 'default_value' => false }),
    Enum['ldap', 'remote_user'] $auth_backend   = lookup('profile::hue::auth_backend', { 'default_value' => 'ldap' }),
){

    # Require that all Hue applications
    # have their corresponding clients
    # and configs installed.
    # Include Hadoop ecosystem client classes.
    require ::profile::hadoop::common
    require ::profile::hadoop::httpd
    require ::profile::hive::client

    require ::profile::analytics::httpd::utils

    # These don't require any extra configuration,
    # so no role class is needed.
    class { '::bigtop::sqoop': }
    class { '::bigtop::mahout': }

    class { '::passwords::ldap::production': }

    # For snappy support with Hue.
    if debian::codename::eq('buster') {
        ensure_packages('python-snappy')
    } else {
        ensure_packages('python3-snappy')
    }

    class { '::bigtop::hue':
        # We always host hive-server on the same node as hive-metastore.
        hive_server_host           => $hive_server_host,
        hive_thrift_version        => $hive_thrift_version,
        smtp_host                  => 'localhost',
        database_host              => $database_host,
        database_user              => $database_user,
        database_password          => $database_password,
        database_engine            => $database_engine,
        database_name              => $database_name,
        database_port              => $database_port,
        secret_key                 => $session_secret_key,
        smtp_from_email            => "hue@${::fqdn}",
        ldap_url                   => "ldaps://${ldap_config[ro-server]}",
        ldap_bind_dn               => "cn=proxyagent,ou=profile,${ldap_base_dn}",
        ldap_bind_password         => $passwords::ldap::production::proxypass,
        ldap_base_dn               => $ldap_base_dn,
        ldap_username_pattern      => 'uid=<username>,ou=people,dc=wikimedia,dc=org',
        ldap_user_filter           => 'objectclass=person',
        ldap_user_name_attr        => 'uid',
        ldap_group_filter          => 'objectclass=posixgroup',
        ldap_group_member_attr     => 'member',
        ldap_create_users_on_login => $ldap_create_users_on_login,
        # Disable hue's SSL.  SSL terminiation is handled by an upstream proxy.
        ssl_private_key            => false,
        ssl_certificate            => false,
        secure_proxy_ssl_header    => true,
        kerberos_keytab            => $kerberos_keytab,
        kerberos_principal         => $kerberos_principal,
        kerberos_kinit_path        => $kerberos_kinit_path,
        use_yarn_ssl_config        => $use_yarn_ssl_config,
        use_hdfs_ssl_config        => $use_hdfs_ssl_config,
        use_mapred_ssl_config      => $use_mapred_ssl_config,
        use_hue4_settings          => $use_hue4_settings,
        auth_backend               => $auth_backend,
    }

    # Include icinga alerts if production realm.

    if $use_hue4_settings {
        if $monitoring_enabled {
            nrpe::monitor_service { 'hue-gunicorn':
                description   => 'Hue Gunicorn Python server',
                nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1: -a "/usr/lib/hue/build/env/bin/python3.7 /usr/lib/hue/build/env/bin/hue rungunicornserver"',
                contact_group => 'team-data-platform',
                require       => Class['bigtop::hue'],
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Cluster/Hue/Administration',
            }
            if $kerberos_kinit_path {
                nrpe::monitor_service { 'hue-kt-renewer':
                    description   => 'Hue Kerberos keytab renewer',
                    nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -a "/usr/lib/hue/build/env/bin/python3.7 /usr/lib/hue/build/env/bin/hue kt_renewer"',
                    contact_group => 'team-data-platform',
                    require       => Class['bigtop::hue'],
                    notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Cluster/Hue/Administration',
                }
            }
        }
    } else {
        if $monitoring_enabled {
            nrpe::monitor_service { 'hue-cherrypy':
                description   => 'Hue CherryPy python server',
                nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C python2.7 -a "/usr/lib/hue/build/env/bin/hue runcherrypyserver"',
                contact_group => 'team-data-platform',
                require       => Class['bigtop::hue'],
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Cluster/Hue/Administration',
            }
            if $kerberos_kinit_path {
                nrpe::monitor_service { 'hue-kt-renewer':
                    description   => 'Hue Kerberos keytab renewer',
                    nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C python2.7 -a "/usr/lib/hue/build/env/bin/hue kt_renewer"',
                    contact_group => 'team-data-platform',
                    require       => Class['bigtop::hue'],
                    notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Cluster/Hue/Administration',
                }
            }
        }
    }

    # Vhost proxy to Hue app server.
    # This is not for LDAP auth, LDAP is done by Hue itself.

    $hue_port = $::bigtop::hue::http_port

    if $enable_cas {
        profile::idp::client::httpd::site {$server_name:
            vhost_content    => 'profile/idp/client/httpd-hue.erb',
            document_root    => '/var/www',
            proxied_as_https => true,
            vhost_settings   => { 'hue_port' => $hue_port },
            required_groups  => [
                'cn=ops,ou=groups,dc=wikimedia,dc=org',
                'cn=wmf,ou=groups,dc=wikimedia,dc=org',
                'cn=nda,ou=groups,dc=wikimedia,dc=org',
            ]
        }
        profile::auto_restarts::service { 'envoyproxy': }
    } else {
        httpd::site { $server_name:
            content => template('profile/hue/hue.vhost.erb'),
            require => File['/var/www/health_check'],
        }
    }

    profile::auto_restarts::service { 'hue': }
    profile::auto_restarts::service { 'apache2': }
}
