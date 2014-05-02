# MariaDB 10 multi-source replication

define mariadb::monitor_replication(
    $is_critical   = true,
    $contact_group = 'dba',
    $lag_warn      = 60,
    $lag_crit      = 300,
    $socket        = '/tmp/mysql.sock',
    ) {

    include passwords::nagios::mysql
    $password = $passwords::nagios::mysql::mysql_check_pass

    $check_mariadb = "/usr/lib/nagios/plugins/check_mariadb.pl --sock=${socket} --user=nagios --pass=${password} --set=default_master_connection=${name}"

    nrpe::monitor_service { "mariadb_slave_io_state_${name}":
        description   => "MariaDB Slave IO: ${name}",
        nrpe_command  => "${check_mariadb} --check=slave_io_state",
        critical      => true,
        contact_group => $contact_group,
    }

    nrpe::monitor_service { "mariadb_slave_sql_state_${name}":
        description   => "MariaDB Slave SQL: ${name}",
        nrpe_command  => "${check_mariadb} --check=slave_sql_state",
        critical      => true,
        contact_group => $contact_group,
    }

    nrpe::monitor_service { "mariadb_slave_sql_lag_${name}":
        description   => "MariaDB Slave Lag: ${name}",
        nrpe_command  => "${check_mariadb} --check=slave_sql_lag --sql-lag-warn=${lag_warn} --sql-lag-crit=${lag_crit}",
        critical      => true,
        contact_group => $contact_group,
    }
}