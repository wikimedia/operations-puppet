#include "mysql.db"

class role::labs-mysql-server {

    $datadir = $::mysql_datadir ? {
        undef   => '/mnt/mysql',
        default => $::mysql_datadir,
    }
    $bind_address = $::mysql_server_bind_address ? {
        undef   => '127.0.0.1',
        default => $::mysql_server_bind_address
    }

    class { 'mysql::server':
        config_hash => {
            # Move mysql data to a place where there's actually space.
            'datadir' => $datadir,
            'bind_address' => $bind_address,
        }
    }
}
