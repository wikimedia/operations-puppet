# Sets up a maps server slave
class role::maps::slave {
    include ::postgresql::slave
    include ::role::maps::postgresql_common

    system::role { 'role::maps::slave':
        ensure      => 'present',
        description => 'Maps Postgres slave',
    }

    $pg_password = hiera('postgresql::slave::replication_pass')
    $critical = 1800
    $warning = 300
    $command = "/usr/lib/nagios/plugins/check_postgres_replication_lag.py \
-U replication -P ${pg_password} -D template1 -C ${critical} -W ${warning}"
    nrpe::monitor::service { 'postgres-rep-lag':
        description   => 'Postgres Replication Lag',
        nrpe_command => $command,
    }
}

