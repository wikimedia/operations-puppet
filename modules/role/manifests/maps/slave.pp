# Sets up a maps server slave
class role::maps::slave {
    include ::postgresql::slave
    include ::role::maps::postgresql_common

    system::role { 'role::maps::slave':
        ensure      => 'present',
        description => 'Maps Postgres slave',
    }
    $master = hiera('postgresql::slave::master_server')

    $monitoring_pass = hiera('postgresql::slave::monitoring_pass')
    $critical = 1800
    $warning = 300
    $command = "/usr/lib/nagios/plugins/check_postgres_replication_lag.py \
-U icinga -P ${monitoring_pass} -m ${master} -D template1 -C ${critical} -W ${warning}"
    nrpe::monitor_service { 'postgres-rep-lag':
        description  => 'Postgres Replication Lag',
        nrpe_command => $command,
    }
}

