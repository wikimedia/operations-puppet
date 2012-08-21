# various utility scripts for core dbs
class coredb::utils {
	file {
		"/usr/local/bin/master_id.py":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///modules/coredb/utils/master_id.py";
		"/etc/profile.d/mysqlpath.sh":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///modules/coredb/utils/mysqlpath.sh";
	}
}
