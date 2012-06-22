#include "mysql.db"

class role::labs-mysql-server {
	if !$mysql_datadir {
		datadir = "/mnt/mysql"
	} else {
		datadir = $mysql_datadir
	}
	if !$mysql_file_per_table {
		file_per_table = "1"
	} else {
		file_per_table = $mysql_file_per_table
	}
	class { "generic::mysql::server":
		# Move mysql data to a place where there's actually space.
		datadir => $datadir,
		innodb_file_per_table => $file_per_table,
	}
}
