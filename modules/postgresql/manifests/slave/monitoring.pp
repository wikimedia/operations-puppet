# check_postgres_hot_standby_delay script relies on values that are only
# readable by superuser or replication user. This prevents using a
# dedicated user for monitoring.
class postgresql::slave::monitoring(
    $pg_master,
    $pg_password,
    $pg_user = 'replication',
    $pg_database = 'template1',
    $critical = 16777216, # 16Mb
    $warning = 1048576, # 1Mb
) {

    $icinga_command = "/usr/bin/check_postgres_hot_standby_delay \
--host=${pg_master},localhost --dbuser=${pg_user} \
--dbpass=${pg_password} -dbname=${pg_database} \
--warning=${warning} --critical=${critical}"

    nrpe::monitor_service { 'postgres-rep-lag':
        description  => 'Postgres Replication Lag',
        nrpe_command => $icinga_command,
    }

}