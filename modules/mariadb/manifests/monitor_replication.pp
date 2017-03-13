# MariaDB 10 multi-source replication
# TODO: Revisit the is_critical part. We probably want pages for DB problems for
# at least a group of people
define mariadb::monitor_replication(
    $is_critical   = true,
    $contact_group = 'dba',
    $lag_warn      = 60,
    $lag_crit      = 300,
    $socket        = '/tmp/mysql.sock',
    $multisource   = true,
    $warn_stopped  = true,
    ) {

    include passwords::nagios::mysql
    $password = $passwords::nagios::mysql::mysql_check_pass

    $check_command = "/usr/lib/nagios/plugins/check_mariadb.pl --sock=${socket} --user=nagios --pass=${password}"

    $check_set = $multisource ? {
        true  => "--set=default_master_connection=${name}",
        false => ''
    }

    $check_warn = $warn_stopped ? {
        true  => '--warn-stopped',
        false => '--no-warn-stopped'
    }

    $check_mariadb = "${check_command} ${check_set} ${check_warn}"

    nrpe::monitor_service { "mariadb_slave_io_state_${name}":
        description   => "MariaDB Slave IO: ${name}",
        nrpe_command  => "${check_mariadb} --check=slave_io_state",
        critical      => $is_critical,
        contact_group => $contact_group,
    }

    nrpe::monitor_service { "mariadb_slave_sql_state_${name}":
        description   => "MariaDB Slave SQL: ${name}",
        nrpe_command  => "${check_mariadb} --check=slave_sql_state",
        critical      => $is_critical,
        contact_group => $contact_group,
    }

    # check the lag towards the mw_primary datacenter's master
    nrpe::monitor_service { "mariadb_slave_sql_lag_${name}":
        description   => "MariaDB Slave Lag: ${name}",
        nrpe_command  => "${check_mariadb} --check=slave_sql_lag \
                          --shard=${name} --datacenter=${::mw_primary} \
                          --sql-lag-warn=${lag_warn} \
                          --sql-lag-crit=${lag_crit}",
        retries       => 10,
        critical      => $is_critical,
        contact_group => $contact_group,
    }
}
