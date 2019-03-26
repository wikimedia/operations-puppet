# == Class role::analytics_cluster::oozie::server
#
# Installs the Oozie server.
#
class profile::oozie::server(
    $monitoring_enabled                       = hiera('profile::oozie::server::monitoring_enabled', false),
    $ferm_srange                              = hiera('profile::oozie::server::ferm_srange', '$DOMAIN_NETWORKS'),
    $jvm_opts                                 = hiera('profile::oozie::server::jvm_opts', '-Xmx2048m'),
    $java_home                                = hiera('profile::oozie::server::java_home', '/usr/lib/jvm/java-8-openjdk-amd64/jre'),
    $oozie_service_kerberos_enabled           = hiera('profile::oozie::server::oozie_service_kerberos_enabled', undef),
    $local_realm                              = hiera('profile::oozie::server::local_realm', undef),
    $oozie_service_keytab_file                = hiera('profile::oozie::server::oozie_service_keytab_file', undef),
    $oozie_service_kerberos_principal         = hiera('profile::oozie::server::oozie_service_kerberos_principal', undef),
    $oozie_authentication_type                = hiera('profile::oozie::server::oozie_authentication_type', undef),
    $oozie_authentication_kerberos_principal  = hiera('profile::oozie::server::oozie_authentication_kerberos_principal', undef),
    $oozie_authentication_kerberos_name_rules = hiera('profile::oozie::server::oozie_authentication_kerberos_name_rules', undef),
    $use_kerberos                             = hiera('profile::oozie::server::use_kerberos', false),
    $jdbc_database                            = hiera('profile::oozie::server::jdbc_database', undef),
    $jdbc_username                            = hiera('profile::oozie::server::jdbc_username', undef),
    $jdbc_password                            = hiera('profile::oozie::server::jdbc_password', undef),
) {
    require ::profile::oozie::client

    # cdh::oozie::server will ensure that its MySQL DB is
    # properly initialized.  For puppet to do this,
    # it needs a mysql client.
    require_package('mysql-client')

    class { '::cdh::oozie::server':
        smtp_host                                   => 'localhost',
        smtp_from_email                             => "oozie@${::fqdn}",
        # This is not currently working.  Disabling
        # this allows any user to manage any Oozie
        # job.  Since access to our cluster is limited,
        # this isn't a big deal.  But, we should still
        # figure out why this isn't working and
        # turn it back on.
        # I was not able to kill any oozie jobs
        # with this on, even though the
        # oozie.service.ProxyUserService.proxyuser.*
        # settings look like they are properly configured.
        authorization_service_authorization_enabled => false,
        jvm_opts                                    => $jvm_opts,
        java_home                                   => $java_home,
        oozie_service_kerberos_enabled              => $oozie_service_kerberos_enabled,
        local_realm                                 => $local_realm,
        oozie_service_keytab_file                   => $oozie_service_keytab_file,
        oozie_service_kerberos_principal            => $oozie_service_kerberos_principal,
        oozie_authentication_type                   => $oozie_authentication_type,
        oozie_authentication_kerberos_principal     => $oozie_authentication_kerberos_principal,
        oozie_authentication_kerberos_name_rules    => $oozie_authentication_kerberos_name_rules,
        use_kerberos                                => $use_kerberos,
        jdbc_database                               => $jdbc_database,
        jdbc_username                               => $jdbc_username,
        jdbc_password                               => $jdbc_password,
    }

    # Oozie is creating event logs in /var/log/oozie.
    # It rotates them but does not delete old ones.  Set up cronjob to
    # delete old files in this directory.
    cron { 'oozie-clean-logs':
        command => 'test -d /var/log/oozie && /usr/bin/find /var/log/oozie -type f -mtime +7 -exec rm {} >/dev/null \;',
        minute  => 5,
        hour    => 0,
        require => Class['cdh::oozie::server'],
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
            require       => Class['cdh::hive::metastore'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Oozie',
        }
    }
}
