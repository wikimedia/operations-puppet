# coredb required packages
class coredb::conf {

		file {
			"/etc/db.cluster":
				content => "${::shard}";
			"/etc/my.cnf":
				content => template("coredb/prod.my.cnf.erb");
			"/etc/mysql/my.cnf":
				source => "puppet:///modules/coredb/confs/empty-my.cnf";
		}


}
