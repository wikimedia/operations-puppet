class coredb_mysql(
    $shard,
    $mariadb,
    $read_only,
    $skip_name_resolve,
    $mysql_myisam,
    $mysql_max_allowed_packet,
    $disable_binlogs,
    $innodb_log_file_size,
    $innodb_file_per_table,
    $long_timeouts,
    $enable_unsafe_locks,
    $large_slave_trans_retries,
    $slow_query_digest,
    $heartbeat_enabled
) {

    include coredb_mysql::base
    include coredb_mysql::packages
    include coredb_mysql::utils

    if $slow_query_digest == true {
        include coredb_mysql::slow_digest
    }

    if $heartbeat_enabled == true {
        include coredb_mysql::heartbeat
    }

    file { '/etc/db.cluster':
        content => $shard,
    }

    file { '/etc/my.cnf':
        content => template('coredb_mysql/prod.my.cnf.erb'),
    }

    file { '/etc/mysql/my.cnf':
        ensure => link,
        target => '/etc/my.cnf',
    }
    Class['coredb_mysql'] -> Class['coredb_mysql::packages']
}


