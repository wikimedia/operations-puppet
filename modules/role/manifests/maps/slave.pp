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
    $command = "/usr/lib/nagios/plugins/check_postgres_replication_lag.py \
-U replication -P ${replication_pass} -m ${master} -D template1 -C ${critical} -W ${warning}"

    # This check generate a number of alerts, which recover quickly. It looks
    # like lag suddenly jumps from 0 to a high number (multiple hours) and goes
    # back to zero quickly. Increasing the number of retries will reduce the
    # number of false positive while we investigate a better solution. See
    # T162345 for details.
    nrpe::monitor_service { 'postgres-rep-lag':
        description  => 'Postgres Replication Lag',
        nrpe_command => $command,
        retries      => 10,
    }
}
