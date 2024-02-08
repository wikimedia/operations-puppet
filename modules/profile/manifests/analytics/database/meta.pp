# == Class role::analytics_cluster::database::meta
#
# Installs a MySQL/MariaDB server for use with Hive, Superset, Druid, and DataHub
# and other Analytics Cluster services.
#
class profile::analytics::database::meta(
    Stdlib::Unixpath $datadir   = lookup('profile::analytics::database::meta::datadir', { 'default_value' => '/var/lib/mysql' }),
    Stdlib::Unixpath $tmpdir    = lookup('profile::analytics::database::meta::tmpdir', { 'default_value' => '/srv/tmp' }),
    Boolean $monitoring_enabled = lookup('profile::analytics::database::meta::monitoring_enabled', { 'default_value' => false }),
    String $ferm_srange         = lookup('profile::analytics::database::meta::ferm_srange', { 'default_value' => '$DOMAIN_NETWORKS' }),
    String $innodb_pool_size    = lookup('profile::analytics::database::meta::innodb_pool_size', { 'default_value' => '4G'}),
    Boolean $is_mariadb_replica = lookup('profile::analytics::database::meta::is_mariadb_replica', { 'default_value' => false }),
) {

    require profile::mariadb::packages_wmf
    $basedir = $profile::mariadb::packages_wmf::basedir
    include profile::mariadb::wmfmariadbpy
    include profile::mariadb::monitor::prometheus

    $mariadb_socket = '/run/mysqld/mysqld.sock'

    # If it is the replica, set it as read-only
    # and add monitoring for the replication state.
    if $is_mariadb_replica {
        $read_only = 1
        if $monitoring_enabled {
            mariadb::monitor_replication { 'analytics-meta-replica':
                is_critical   => false,
                contact_group => 'admins,team-data-platform',
            }
        }
    } else {
        $read_only = 0
    }

    class { 'mariadb::config':
        config           => 'profile/analytics/database/meta/analytics-meta.my.cnf.erb',
        socket           => $mariadb_socket,
        port             => 3306,
        datadir          => $datadir,
        tmpdir           => $tmpdir,
        basedir          => $basedir,
        ssl              => 'puppet-cert',
        read_only        => $read_only,
        innodb_pool_size => $innodb_pool_size,
    }

    # If labs, automate mysql_install_db. Supported only for recent
    # Debian OS like Stretch.
    if $::realm == 'labs' {
        exec { 'analytics_meta_mysql_install_db':
            command => "${basedir}/scripts/mysql_install_db",
            cwd     => $basedir,
            creates => "${datadir}/ibdata1",
            require => Class['mariadb::config'],
            before  => Class['mariadb::service'],
        }
    }

    class { 'mariadb::service':
        ensure  => 'running',
        manage  => true,
        enable  => true,
        require => Class['mariadb::config'],
    }

    # Allow access to this analytics mysql instance from analytics networks.
    # Allow also the Druid public cluster to use it as storage for daemons
    # like the coordinator. The Druid analytics cluster already uses it but it
    # is already included in the ANALYTICS_NETWORKS definition.
    ferm::service{ 'analytics-mysql-meta':
        proto  => 'tcp',
        port   => '3306',
        srange => $ferm_srange,
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        nrpe::monitor_service { 'mysql_analytics-meta':
            description   => 'analytics-meta MySQL instance',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C mysqld',
            contact_group => 'admins,team-data-platform',
            require       => Class['mariadb::service'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Mysql_Meta',
        }
    }
}
