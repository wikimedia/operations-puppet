class role::coredb::config {
	$topology = {
		's1' => {
			'hosts' => ['db32', 'db36', 'db38', 'db59', 'db60', 'db63', 'db67',
				'db1001', 'db1017', 'db1042', 'db1043', 'db1047', 'db1049', 'db1050'],
			'primary_site' => "pmtpa",
			'masters' => {'pmtpa' => "db63", 'eqiad' => "db1017"},
			'snapshot' => ["db32", "db1050"],
			'no_master' => [ 'db67', 'db1047' ]
		},
		's2' => {
			'hosts' => ['db52', 'db53', 'db54', 'db57', 'db1002', 'db1009', 'db1018', 'db1034'],
			'primary_site' => "pmtpa",
			'masters' => {'pmtpa' => "db54", 'eqiad' => "db1034"},
			'snapshot' => ["db53", "db1018"],
			'no_master' => []
		},
		's3' => {
			'hosts' => ['db34', 'db39', 'db64', 'db66', 'db1003', 'db1010', 'db1019', 'db1035'],
			'primary_site' => "pmtpa",
			'masters' => {'pmtpa' => "db34", 'eqiad' => "db1019"},
			'snapshot' => ["db64", "db1035"],
			'no_master' => []
		},
		's4' => {
			'hosts' => ['db31', 'db33', 'db51', 'db65', 'db1004', 'db1011', 'db1020', 'db1038'],
			'primary_site' => "pmtpa",
			'masters' => {'pmtpa' => "db31", 'eqiad' => "db1038"},
			'snapshot' => ["db33", "db1020"],
			'no_master' => []
		},
		's5' => {
			'hosts' => ['db35', 'db44', 'db45', 'db55', 'db1005', 'db1021', 'db1026', 'db1039'],
			'primary_site' => "pmtpa",
			'masters' => {'pmtpa' => "db45", 'eqiad' => "db1039"},
			'snapshot' => ["db44", "db1005"],
			'no_master' => []
		},
		's6' => {
			'hosts' => ['db43', 'db46', 'db47', 'db50', 'db1006', 'db1022', 'db1027', 'db1040'],
			'primary_site' => "pmtpa",
			'masters' => {'pmtpa' => "db47", 'eqiad' => "db1006"},
			'snapshot' => ["db46", "db1022"],
			'no_master' => []
		},
		's7' => {
			'hosts' => ['db37', 'db56', 'db58', 'db68', 'db1007', 'db1024', 'db1028', 'db1041'],
			'primary_site' => "pmtpa",
			'masters' => {'pmtpa' => "db37", 'eqiad' => "db1041"},
			'snapshot' => ["db56", "db1007"],
			'no_master' => []
		},
		'm1' => {
			'hosts' => ['bellin', 'blondel'],
			'primary_site' => "pmtpa",
			'masters' => {'pmtpa' => "blondel"},
			'snapshot' => [],
			'no_master' => []
		},
		'm2' => {
			'hosts' => ['db48', 'db49', 'db1046', 'db1048'],
			'primary_site' => "both",
			'masters' => {'pmtpa' => "db48", 'eqiad' => "db1048"},
			'snapshot' => ["db49", "db1046"],
			'no_master' => []
		},
		'es1' => {
			'hosts' => ['es1', 'es2', 'es3', 'es4', 'es1001', 'es1002', 'es1003', 'es1004'],
			'primary_site' => "pmtpa",
			'masters' => {},
			'snapshot' => [],
			'no_master' => []
		},
		'es2' => {
			'hosts' => ['es5', 'es6', 'es7', 'es1005', 'es1006', 'es1007'],
			'primary_site' => "pmtpa",
			'masters' => {'pmtpa' => "es5", 'eqiad' => "es1005"},
			'snapshot' => ["es7", "es1007"],
			'no_master' => []
		},
		'es3' => {
			'hosts' => ['es8', 'es9', 'es10', 'es1008', 'es1009', 'es1010'],
			'primary_site' => "pmtpa",
			'masters' => {'pmtpa' => "es8", 'eqiad' => "es1008"},
			'snapshot' => ["es10", "es1010"],
			'no_master' => []
		},
	}
}

class role::coredb::s1 {
	class { "role::coredb::common":
		shard => "s1",
		innodb_log_file_size => "2000M"
	}
}

class role::coredb::s2 {
	class { "role::coredb::common":
		shard => "s2",
		innodb_log_file_size => "2000M"
	}
}

class role::coredb::s3 {
	class { "role::coredb::common":
		shard => "s3",
	}
}

class role::coredb::s4 {
	class { "role::coredb::common":
		shard => "s4",
		innodb_log_file_size => "2000M"
	}
}

class role::coredb::s5 {
	class { "role::coredb::common":
		shard => "s5",
		innodb_log_file_size => "1000M"
	}
}

class role::coredb::s6 {
	class { "role::coredb::common":
		shard => "s6",
	}
}

class role::coredb::s7 {
	class { "role::coredb::common":
		shard => "s7",
	}
}

class role::coredb::m1 {
	class { "role::coredb::common":
		shard => "m1",
		innodb_file_per_table => true,
	}
}

class role::coredb::m2 {
	class { "role::coredb::common":
		shard => "m2",
		innodb_file_per_table => true,
		skip_name_resolve => false,
		mysql_max_allowed_packet => 1073741824,
	}
}

class role::coredb::es1 {
	class { "role::coredb::common":
		shard => "es1",
		innodb_file_per_table => true,
		slow_query_digest => false,
	}
}

class role::coredb::es2 {
	class { "role::coredb::common":
		shard => "es2",
		innodb_file_per_table => true,
		slow_query_digest => false,
	}
}

class role::coredb::es3 {
	class { "role::coredb::common":
		shard => "es3",
		innodb_file_per_table => true,
		slow_query_digest => false,
	}
}

class role::coredb::researchdb( $shard="s1", $innodb_log_file_size = "2000M" ){
	class { "role::coredb::common":
		shard => $shard,
		innodb_log_file_size => $innodb_log_file_size,
		read_only => false,
		disable_binlogs => true,
		long_timeouts => true,
		enable_unsafe_locks => true,
		large_slave_trans_retries => true,
	}
}

class role::coredb::common(
	$shard,
	$read_only = true,
	$skip_name_resolve = true,
	$mysql_myisam = false,
	$mysql_max_allowed_packet = "16M",
	$disable_binlogs = false,
	$innodb_log_file_size = "500M",
	$innodb_file_per_table = false,
	$long_timeouts = false,
	$enable_unsafe_locks = false,
	$large_slave_trans_retries = false,
	$slow_query_digest = true,
	$mariadb = false,
	) inherits role::coredb::config {

	$cluster = "mysql"

	system_role { "dbcore": description => "Shard ${shard} Core Database server" }

	include standard,
		mysql::coredb::ganglia

	if $topology[$shard]['masters'][$::site] == $::hostname {
		class { "coredb_mysql":
			shard => $shard,
			read_only => false,
			skip_name_resolve => $skip_name_resolve,
			mysql_myisam => $mysql_myisam,
			mysql_max_allowed_packet => $mysql_max_allowed_packet,
			disable_binlogs => $disable_binlogs,
			innodb_log_file_size => $innodb_log_file_size,
			innodb_file_per_table => $innodb_file_per_table,
			long_timeouts => $long_timeouts,
			enable_unsafe_locks => $enable_unsafe_locks,
			large_slave_trans_retries => $large_slave_trans_retries,
			slow_query_digest => $slow_query_digest,
			mariadb => $mariadb
		}

		class { "mysql::coredb::monitoring": crit => true }

	}
	else {
		class { "coredb_mysql":
			shard => $shard,
			read_only => $read_only,
			skip_name_resolve => $skip_name_resolve,
			mysql_myisam => $mysql_myisam,
			mysql_max_allowed_packet => $mysql_max_allowed_packet,
			disable_binlogs => $disable_binlogs,
			innodb_log_file_size => $innodb_log_file_size,
			innodb_file_per_table => $innodb_file_per_table,
			long_timeouts => $long_timeouts,
			enable_unsafe_locks => $enable_unsafe_locks,
			large_slave_trans_retries => $large_slave_trans_retries,
			slow_query_digest => $slow_query_digest,
			mariadb => $mariadb
		}

		class { "mysql::coredb::monitoring": crit => false }
	}

	if $::hostname in $topology[$shard]['snapshot'] {
		include coredb_mysql::snapshot
	}
}
