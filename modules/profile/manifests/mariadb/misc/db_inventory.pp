class profile::mariadb::misc::db_inventory(
    Optional[String[1]] $innodb_pool_size = lookup('profile::mariadb::misc::db_inventory::innodb_pool_size', {'default_value' => undef}),
) {
    include passwords::misc::scripts

    include profile::mariadb::mysql_role
    include profile::mariadb::misc::tendril
    include profile::mariadb::misc::zarcillo

    $id = 'db_inventory'
    $is_master = $profile::mariadb::mysql_role::role == 'master'
    $binlog_format = $is_master ? {
        true    => 'STATEMENT',
        default => 'ROW',
    }

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    profile::mariadb::ferm { $id: }

    class { 'mariadb::config':
        basedir          => $profile::mariadb::packages_wmf::basedir,
        config           => 'profile/mariadb/mysqld_config/db_inventory.my.cnf.erb',
        datadir          => '/srv/sqldata',
        tmpdir           => '/srv/tmp',
        binlog_format    => $binlog_format,
        p_s              => 'on',
        ssl              => 'puppet-cert',
        innodb_pool_size => $innodb_pool_size,
    }

    include profile::mariadb::monitor::prometheus

    mariadb::monitor_replication { $id: }
    mariadb::monitor_readonly { $id:
        # XXX(kormat): while the orchestrator database is hosted on db2093,
        # both nodes need to be read-write. T266003 for context.
        # read_only     => !($is_master),
        read_only => false,
    }
    profile::mariadb::replication_lag { $id: }
    class { 'mariadb::monitor_disk': }
    class { 'mariadb::monitor_process': }

    class { 'mariadb::heartbeat':
        shard      => $id,
        datacenter => $::site,
        enabled    => $is_master,
    }

    class { 'mariadb::monitor_memory': }
}
