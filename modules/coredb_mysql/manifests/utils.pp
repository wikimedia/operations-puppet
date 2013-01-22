# various utility scripts for core dbs
class coredb_mysql::utils {
	file {
		"/usr/local/bin/master_id.py":
			owner => root,
			group => root,
			mode => 0555,
			content => template("coredb_mysql/master_id.py.erb");
	}
}
