#include "mysql.db"

class role::labs::db::master {

    system::role { 'role::labs::db::master': description => "Labs user database master" }

    class { 'mysql::server':
        config_hash => {
            'datadir'                 => '/srv/labsdb',
            'port'                    => '3306',
            'bind_address'            => '0.0.0.0',
            'max_connections'         => '4096',

            'server-id'               => '1',
            'report_host'             => 'labsdbmaster',
            'log_bin'                 => true,
            'max_binlog_size'         => '100M',

            'innodb_log_file_size'    => '64M',
            'innodb_buffer_pool_size' => '13G',
            'innodb_log_buffer_size'  => '64M',
            'innodb_file_per_table'   => '1',
            'innodb_open_files'       => '512',
            'innodb_flush_method'     => 'O_DIRECT',

            # More tuning will certainly be needed
        }
    }
}


class role::labs::db::slave {

    system::role { 'role::labs::db::slave': description => "Labs user database slave" }

    class { 'mysql::server':
        config_hash => {
            'datadir'                 => '/srv/labsdb',
            'port'                    => '3306',
            'bind_address'            => '0.0.0.0',
            'max_connections'         => '4096',

            'server-id'               => '2',
            'report_host'             => 'labsdbslave',
            'log_bin'                 => true,
            'max_binlog_size'         => '100M',
            'relay_log'               => '/srv/labsdb/relay',
            'relay_log_index'         => '/srv/labsdb/relay.index',
            'relay_log_info_file'     => '/srv/labsdb/relay.info',

            'innodb_log_file_size'    => '64M',
            'innodb_buffer_pool_size' => '13G',
            'innodb_log_buffer_size'  => '64M',
            'innodb_file_per_table'   => '1',
            'innodb_open_files'       => '512',
            'innodb_flush_method'     => 'O_DIRECT',

            # More tuning will certainly be needed
        }
    }
}
