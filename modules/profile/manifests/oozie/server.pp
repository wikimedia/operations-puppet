# == Class role::analytics_cluster::oozie::server
#
# Installs the Oozie server.
#
class profile::oozie::server(
    Boolean $monitoring_enabled                                = lookup('profile::oozie::server::monitoring_enabled', { 'default_value' => false }),
    String $ferm_srange                                        = lookup('profile::oozie::server::ferm_srange', { 'default_value' => '$DOMAIN_NETWORKS' }),
    String $jvm_opts                                           = lookup('profile::oozie::server::jvm_opts', { 'default_value' => '-Xmx2048m' }),
    Stdlib::Unixpath $java_home                                = lookup('profile::oozie::server::java_home', { 'default_value' => '/usr/lib/jvm/java-8-openjdk-amd64/jre' }),
    Optional[Boolean] $oozie_service_kerberos_enabled          = lookup('profile::oozie::server::oozie_service_kerberos_enabled', { 'default_value' => undef }),
    Optional[String] $local_realm                              = lookup('profile::oozie::server::local_realm', { 'default_value' => undef }),
    Optional[Stdlib::Unixpath] $oozie_service_keytab_file      = lookup('profile::oozie::server::oozie_service_keytab_file', { 'default_value' => undef }),
    Optional[String] $oozie_service_kerberos_principal         = lookup('profile::oozie::server::oozie_service_kerberos_principal', { 'default_value' => undef }),
    Optional[String] $oozie_authentication_type                = lookup('profile::oozie::server::oozie_authentication_type', { 'default_value' => undef }),
    Optional[String] $oozie_authentication_kerberos_principal  = lookup('profile::oozie::server::oozie_authentication_kerberos_principal', { 'default_value' => undef }),
    Optional[String] $oozie_authentication_kerberos_name_rules = lookup('profile::oozie::server::oozie_authentication_kerberos_name_rules', { 'default_value' => undef }),
    Boolean $hcatalog_enabled                                  = lookup('profile::oozie::server::hcatalog_enabled', { 'default_value' => true }),
    Stdlib::Host $jdbc_host                                    = lookup('profile::oozie::server::jdbc_host', { 'default_value' => 'localhost' }),
    Stdlib::Port $jdbc_port                                    = lookup('profile::oozie::server::jdbc_port', { 'default_value' => 3306 }),
    Optional[String] $jdbc_database                            = lookup('profile::oozie::server::jdbc_database', { 'default_value' => undef }),
    Optional[String] $jdbc_username                            = lookup('profile::oozie::server::jdbc_username', { 'default_value' => undef }),
    Optional[String] $jdbc_password                            = lookup('profile::oozie::server::jdbc_password', { 'default_value' => undef }),
    Optional[Stdlib::Unixpath] $spark_defaults_config_dir      = lookup('profile::oozie::server::spark_defaults_config_dir', { 'default_value' => undef }),
    Stdlib::Unixpath $oozie_sharelib_archive                   = lookup('profile::oozie::server::oozie_sharelib_archive', { 'default_value' => '/usr/lib/oozie/lib' }),
    Array[String] $oozie_admin_users                           = lookup('profile::oozie::server::admin_users', { 'default_value' => ['hdfs'] }),
    Boolean $use_admins_list                                   = lookup('profile::oozie::server::use_admins_list', { 'default_value' => false }),
    Array[String] $oozie_admin_groups                          = lookup('profile::oozie::server::admin_groups', { 'default_value' => [] }),
){

    require ::profile::oozie::client

    # bigtop::oozie::server will ensure that its MySQL DB is
    # properly initialized.  For puppet to do this,
    # it needs a mysql client.
    require_package('default-mysql-client')

    if debian::codename::ge('buster') {
        $jdbc_driver = 'org.mariadb.jdbc.Driver'
    } else {
        $jdbc_driver = 'com.mysql.jdbc.Driver'
    }

    class { '::bigtop::oozie::server':
        smtp_host                                   => 'localhost',
        smtp_from_email                             => "oozie@${::fqdn}",
        authorization_service_authorization_enabled => $use_admins_list,
        admin_users                                 => $oozie_admin_users,
        admin_groups                                => $oozie_admin_groups,
        jvm_opts                                    => $jvm_opts,
        java_home                                   => $java_home,
        oozie_service_kerberos_enabled              => $oozie_service_kerberos_enabled,
        local_realm                                 => $local_realm,
        oozie_service_keytab_file                   => $oozie_service_keytab_file,
        oozie_service_kerberos_principal            => $oozie_service_kerberos_principal,
        oozie_authentication_type                   => $oozie_authentication_type,
        oozie_authentication_kerberos_principal     => $oozie_authentication_kerberos_principal,
        oozie_authentication_kerberos_name_rules    => $oozie_authentication_kerberos_name_rules,
        hcatalog_enabled                            => $hcatalog_enabled,
        jdbc_host                                   => $jdbc_host,
        jdbc_port                                   => $jdbc_port,
        jdbc_database                               => $jdbc_database,
        jdbc_username                               => $jdbc_username,
        jdbc_password                               => $jdbc_password,
        jdbc_driver                                 => $jdbc_driver,
        spark_defaults_config_dir                   => $spark_defaults_config_dir,
        oozie_sharelib_archive                      => $oozie_sharelib_archive,
    }

    ferm::service{ 'oozie_server':
        proto  => 'tcp',
        port   => '11000',
        srange => $ferm_srange,
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        include ::profile::oozie::monitoring::server

        nrpe::monitor_service { 'oozie':
            description   => 'Oozie Server',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.catalina.startup.Bootstrap"',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hive::metastore'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Oozie',
        }
    }
}
