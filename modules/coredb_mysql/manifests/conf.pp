# coredb_mysql required packages
class coredb_mysql::conf {

		file {
			"/etc/db.cluster":
				content => $coredb_mysql::shard;
			"/etc/my.cnf":
				content => template("coredb_mysql/prod.my.cnf.erb");
			"/etc/mysql/my.cnf":
				ensure => "/etc/my.cnf"
		}


}
