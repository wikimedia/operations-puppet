#include "mysql.db"

class role::labs-mysql-server-new {

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
            'datadir' => $role::labs-mysql-server::datadir,
            'bind_address' => $role::labs-mysql-server::bind_address,
        }
    }
}

class role::labs-mysql-server {
	class { "generic::mysql::server":
		# Move mysql data to a place where there's actually space.
		datadir => $::mysql_datadir ? {
			undef => "/mnt/mysql",
			default => $::mysql_datadir,
		},
		innodb_file_per_table => $::mysql_file_per_table ? {
			undef => "1",
			default => $::mysql_file_per_table,
		},
		version => $::lsbdistrelease ? {
			"12.04" => "5.5",
			default => false,
		},
		bind_address => $mysql_server_bind_address ? {
			undef => "127.0.0.1",
			default => $mysql_server_bind_address
		},
	}
}
