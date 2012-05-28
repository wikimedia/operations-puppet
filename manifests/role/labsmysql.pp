#include "mysql.db"

class role::labs-mysql-server {
	class { "generic::mysql::server":
		datadir => "/mnt/mysql"
	}
}
