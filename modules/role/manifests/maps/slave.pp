# Sets up a maps server slave
class role::maps::slave {
    include ::postgresql::slave
    include ::role::maps::postgresql_common

    system::role { 'role::maps::slave':
        ensure      => 'present',
        description => 'Maps Postgres slave',
    }
    $master = hiera('postgresql::slave::master_server')

    # check_postgres_replication_lag script relies on values that are only
    # readable by superuser or replication user. This prevents using a
    # dedicated user for monitoring.
    $replication_pass = hiera('postgresql::slave::replication_pass')
    $critical = 1800
    $warning = 300
    $icinga_command = "/usr/lib/nagios/plugins/check_postgres_replication_lag.py \
-U replication -P ${replication_pass} -m ${master} -D template1 -C ${critical} -W ${warning}"
    nrpe::monitor_service { 'postgres-rep-lag':
        description  => 'Postgres Replication Lag',
        nrpe_command => $icinga_command,
    }

    $prometheus_command = "/usr/bin/prometheus_postgresql_replication_lag -m ${master} -P ${replication_pass}"
    cron { 'prometheus-pg-replication-lag':
        ensure  => present,
        command => "${prometheus_command} >/dev/null 2>&1",
    }
}
