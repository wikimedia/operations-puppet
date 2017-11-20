class profile::maps::osm_slave(
    $master = hiera('profile::maps::osm_slave::master'),
    # check_postgres_replication_lag script relies on values that are only
    # readable by superuser or replication user. This prevents using a
    # dedicated user for monitoring.
    $replication_pass = hiera('postgresql::slave::replication_pass'),
) {
    require ::profile::maps::postgresql_common

    class { '::postgresql::slave':
        master_server => $master,
        pgversion     => '9.4',
        root_dir      => '/srv/postgresql',
        includes      => 'tuning.conf',
    }

    class { 'postgresql::slave::monitoring':
        pg_master   => $master,
        pg_user     => 'replication',
        pg_password => $replication_pass,
    }

    class { 'postgresql::prometheus':
        require => Class['::postgresql::slave'],
    }

    $prometheus_command = "/usr/bin/prometheus_postgresql_replication_lag -m ${master} -P ${replication_pass}"
    cron { 'prometheus-pg-replication-lag':
        ensure  => present,
        command => "${prometheus_command} >/dev/null 2>&1",
    }

}
