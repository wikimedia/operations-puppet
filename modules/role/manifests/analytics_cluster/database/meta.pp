# == Class role::analytics_cluster::database::meta
# Installs a MySQL/MariaDB server for use with Hive and Oozie
# and other Analytics Cluster services.
#
class role::analytics_cluster::database::meta {
    # Some CDH database init scripts need Java to run.
    require ::role::analytics_cluster::java

    include ::mariadb::packages_wmf

    $config_template = $::realm ? {
        # Production instance has large innodb_buffer_pool_size.
        # Unfortunetly this is not configurable via parameters or
        # hiera with the mariadb::config class.
        'production' => 'mariadb/analytics-meta.my.cnf.production.erb',
        default      => 'mariadb/analytics-meta.my.cnf.erb',
    }

    class { '::mariadb::config':
        config    => $config_template,
        datadir   => '/var/lib/mysql',
        read_only => false,
        require   => Class['mariadb::packages_wmf'],
    }

    # if labs, automate mysql_install_db.
    if $::realm == 'labs' {
        exec { 'analytics_meta_mysql_install_db':
            command => '/opt/wmf-mariadb10/scripts/mysql_install_db',
            cwd     => '/opt/wmf-mariadb10',
            creates => '/var/lib/mysql/ibdata1',
            require => Class['mariadb::config'],
            before  => Class['mariadb::service'],
        }
    }

    class { '::mariadb::service':
        ensure  => 'running',
        manage  => true,
        enable  => true,
        require => Class['mariadb::config'],
    }

    # Allow access to this analytics mysql instance from analytics networks
    ferm::service{ 'analytics-mysql-meta':
        proto  => 'tcp',
        port   => '3306',
        srange => '$ANALYTICS_NETWORKS',
    }

    # Include icinga alerts if production realm.
    if $::realm == 'production' {
        nrpe::monitor_service { 'mysql_analytics-meta':
            description  => 'analytics-meta MySQL instance',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C mysqld',
            require      => Service['mysql'],
        }

        nrpe::monitor_service { 'mysql_analytics-meta_disk_space':
            description   => 'MySQL disk space for analytics-meta instance',
            nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 10g -c 5g -l -p /var/lib/mysql',
            contact_group => 'admins,analytics',
        }
    }
}
