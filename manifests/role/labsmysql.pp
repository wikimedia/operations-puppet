#include "mysql.db"

class role::labs-mysql-server {
	class { "generic::mysql::server":
		# Move mysql data to a place where there's actually space.
		datadir => "/mnt/mysql"
	}
}
