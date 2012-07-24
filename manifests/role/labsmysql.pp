#include "mysql.db"

class role::labs-mysql-server {
	class { "generic::mysql::server":
		# Move mysql data to a place where there's actually space.
		datadir => $::mysql_datadir ? {
			false => "/mnt/mysql",
			default => $::mysql_datadir,
		},
		innodb_file_per_table => $::mysql_file_per_table ? {
			false => "1",
			default => $::mysql_file_per_table,
		},
		version => $::lsbdistrelease ? {
			"12.04" => "5.5",
			default => false,
		},
	}
}
