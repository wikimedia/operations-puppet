# Sets up a maps server slave
class role::maps::slave {
    include ::postgresql::slave
    include ::role::maps::postgresql_common

    system::role { 'role::maps::slave':
        ensure      => 'present',
        description => 'Maps Postgres slave',
    }
    $master = hiera('postgresql::slave::master_server')

    $replication_pass = hiera('postgresql::slave::replication_pass')

    class { 'postgresql::slave::monitoring':
        pg_master   => $master,
        pg_user     => 'replication',
        pg_password => $replication_pass,
    }

    $prometheus_command = "/usr/bin/prometheus_postgresql_replication_lag -m ${master} -P ${replication_pass}"
    cron { 'prometheus-pg-replication-lag':
        ensure  => present,
        command => "${prometheus_command} >/dev/null 2>&1",
    }
}
