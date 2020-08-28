class profile::mariadb::misc::db_inventory{
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
    profile::mariadb::ferm { $id: }

    class { 'mariadb::config':
        basedir       => $profile::mariadb::packages_wmf::basedir,
        config        => 'profile/mariadb/mysqld_config/db_inventory.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        binlog_format => $binlog_format,
        p_s           => 'on',
        ssl           => 'puppet-cert',
    }

    include profile::mariadb::monitor::prometheus

    mariadb::monitor_replication { $id: }
    mariadb::monitor_readonly { $id:
        read_only     => !($is_master),
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
