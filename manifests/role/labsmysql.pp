#include "mysql.db"

class role::labs-mysql-server {
	class { "generic::mysql::server":
		# Move mysql data to a place where there's actually space.
		datadir => "/mnt/mysql",
		# And, labs has /run instead of /var/run.
		socket => "/run/mysqld/mysqld.sock",
		pid_file => "/run/mysqld/mysqld.pid"
	}
}
