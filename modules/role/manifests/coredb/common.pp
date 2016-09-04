class role::coredb::common(
    $shard,
    $mariadb,
    $logical_cluster = 'mysql',
    $read_only = true,
    $skip_name_resolve = true,
    $mysql_myisam = false,
    $mysql_max_allowed_packet = '16M',
    $disable_binlogs = false,
    $innodb_log_file_size = '500M',
    $innodb_file_per_table = false,
    $long_timeouts = false,
    $enable_unsafe_locks = false,
    $large_slave_trans_retries = false,
    $slow_query_digest = true,
    $heartbeat_enabled = true,
    $contact_group = 'admins',
    ) inherits role::coredb::config {

    $primary_site = $topology[$shard]['primary_site']
    $masters = $topology[$shard]['masters']
    $snapshots = $topology[$shard]['snapshot']

    system::role { 'dbcore': description => "Shard ${shard} Core Database server" }

    ::base::expose_puppet_certs { '/etc/mysql':
        ensure          => present,
        provide_private => true,
        user            => 'mysql',
        group           => 'mysql',
    }

    include standard,
        mha::node,
        cpufrequtils
    class { 'mysql_wmf::coredb::ganglia' : mariadb => $mariadb; }

    if $masters[$::site] == $::hostname
        and ( $primary_site == $::site or $primary_site == 'both' ){
        class { 'coredb_mysql':
            shard                     => $shard,
            mariadb                   => $mariadb,
            read_only                 => false,
            skip_name_resolve         => $skip_name_resolve,
            mysql_myisam              => $mysql_myisam,
            mysql_max_allowed_packet  => $mysql_max_allowed_packet,
            disable_binlogs           => $disable_binlogs,
            innodb_log_file_size      => $innodb_log_file_size,
            innodb_file_per_table     => $innodb_file_per_table,
            long_timeouts             => $long_timeouts,
            enable_unsafe_locks       => $enable_unsafe_locks,
            large_slave_trans_retries => $large_slave_trans_retries,
            slow_query_digest         => $slow_query_digest,
            heartbeat_enabled         => $heartbeat_enabled,
        }

        class { 'mysql_wmf::coredb::monitoring':
            crit          => true,
            contact_group => $contact_group,
        }

    }
    else {
        class { 'coredb_mysql':
            shard                     => $shard,
            mariadb                   => $mariadb,
            read_only                 => $read_only,
            skip_name_resolve         => $skip_name_resolve,
            mysql_myisam              => $mysql_myisam,
            mysql_max_allowed_packet  => $mysql_max_allowed_packet,
            disable_binlogs           => $disable_binlogs,
            innodb_log_file_size      => $innodb_log_file_size,
            innodb_file_per_table     => $innodb_file_per_table,
            long_timeouts             => $long_timeouts,
            enable_unsafe_locks       => $enable_unsafe_locks,
            large_slave_trans_retries => $large_slave_trans_retries,
            slow_query_digest         => $slow_query_digest,
            heartbeat_enabled         => $heartbeat_enabled,
        }

        if $primary_site {
            class { 'mysql_wmf::coredb::monitoring': crit => false }
        } else {
            class { 'mysql_wmf::coredb::monitoring': crit => false, no_slave => true }
        }
    }

    if $::hostname in $snapshots {
        include coredb_mysql::snapshot
    }
}
