# coredb_mysql required packages
class coredb_mysql::conf {

		file {
			"/etc/db.cluster":
				content => "${::shard}";
			"/etc/my.cnf":
				content => template("coredb_mysql/prod.my.cnf.erb");
			"/etc/mysql/my.cnf":
				source => "puppet:///modules/coredb_mysql/confs/empty-my.cnf";
		}


}
