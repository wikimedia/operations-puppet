# MariaDB 10 multi-source replication
# TODO: Revisit the is_critical part. We probably want pages for DB problems for
# at least a group of people
define mariadb::monitor_replication(
    $is_critical   = false,
    $contact_group = 'admins',
    $lag_warn      = 60,
    $lag_crit      = 300,
    $socket        = '/run/mysqld/mysqld.sock',
    $multisource   = false,
    $warn_stopped  = true,
    $source_dc     = mediawiki::state('primary_dc'),
    ) {

    include passwords::nagios::mysql
    $password = $passwords::nagios::mysql::mysql_check_pass

    $check_command = "/usr/local/lib/nagios/plugins/check_mariadb --sock=${socket} --user=nagios --pass=${password}"

    $check_set = $multisource ? {
        true  => "--set=default_master_connection=${name}",
        false => ''
    }

    $check_warn = $warn_stopped ? {
        true  => '--warn-stopped',
        false => '--no-warn-stopped'
    }

    $check_mariadb = "${check_command} ${check_set} ${check_warn}"

    nrpe::monitor_service { "mariadb_replica_io_state_${name}":
        description   => "MariaDB Replica IO: ${name}",
        nrpe_command  => "${check_mariadb} --check=slave_io_state",
        critical      => $is_critical,
        contact_group => $contact_group,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/MariaDB/troubleshooting#Depooling_a_replica',
    }

    nrpe::monitor_service { "mariadb_replica_sql_state_${name}":
        description   => "MariaDB Replica SQL: ${name}",
        nrpe_command  => "${check_mariadb} --check=slave_sql_state",
        critical      => $is_critical,
        contact_group => $contact_group,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/MariaDB/troubleshooting#Depooling_a_replica',
    }

    # check the lag towards the $source_dc's master
    nrpe::monitor_service { "mariadb_replica_sql_lag_${name}":
        description   => "MariaDB Replica Lag: ${name}",
        nrpe_command  => "${check_mariadb} --check=slave_sql_lag \
                          --shard=${name} --datacenter=${source_dc} \
                          --sql-lag-warn=${lag_warn} \
                          --sql-lag-crit=${lag_crit}",
        retries       => 10,
        critical      => $is_critical,
        contact_group => $contact_group,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/MariaDB/troubleshooting#Depooling_a_replica',
    }
}
