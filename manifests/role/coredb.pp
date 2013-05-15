# Virtual resource for the monitoring server
@monitor_group { "es_pmtpa": description => "pmtpa External Storage" }
@monitor_group { "es_eqiad": description => "eqiad External Storage" }
@monitor_group { "mysql_pmtpa": description => "pmtpa mysql core" }
@monitor_group { "mysql_eqiad": description => "eqiad mysql core" }

## for describing replication topology
## hosts must be added here in addition to site.pp
class role::coredb::config {
	$topology = {
		's1' => {
			'hosts' => { 'pmtpa' => [ 'db32', 'db59', 'db60', 'db63', 'db67', 'db69', 'db71' ],
				'eqiad' => [ 'db1017', 'db1043', 'db1049', 'db1050', 'db1051', 'db1052', 'db1056' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "db63", 'eqiad' => "db1056" },
			'snapshot' => [ "db32", "db1050" ],
			'no_master' => [ 'db67', 'db1047' ]
		},
		's2' => {
			'hosts' => { 'pmtpa' => [ 'db52', 'db53', 'db54', 'db57' ],
				'eqiad' => [ 'db1002', 'db1009', 'db1018', 'db1034' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "db54", 'eqiad' => "db1034" },
			'snapshot' => [ "db53", "db1018" ],
			'no_master' => []
		},
		's3' => {
			'hosts' => { 'pmtpa' => [ 'db34', 'db39', 'db64', 'db66' ],
				'eqiad' => [ 'db1003', 'db1010', 'db1019', 'db1035' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "db34", 'eqiad' => "db1019" },
			'snapshot' => [ "db64", "db1035" ],
			'no_master' => []
		},
		's4' => {
			'hosts' => { 'pmtpa' => [ 'db31', 'db51', 'db65', 'db72' ],
				'eqiad' => [ 'db1004', 'db1011', 'db1020', 'db1038', 'db1042', 'db1059' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "db31", 'eqiad' => "db1059" },
			'snapshot' => [ "db65", "db1042" ],
			'no_master' => []
		},
		's5' => {
			'hosts' => { 'pmtpa' => [ 'db44', 'db45', 'db55', 'db73', 'db74' ],
				'eqiad' => [ 'db1005', 'db1021', 'db1026', 'db1039', 'db1058' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "db73", 'eqiad' => "db1058" },
			'snapshot' => [ "db55", "db1005" ],
			'no_master' => []
		},
		's6' => {
			'hosts' => { 'pmtpa' => [ 'db43', 'db46', 'db47', 'db50' ],
				'eqiad' => [ 'db1006', 'db1022', 'db1027', 'db1040' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "db47", 'eqiad' => "db1006" },
			'snapshot' => [ "db46", "db1022" ],
			'no_master' => []
		},
		's7' => {
			'hosts' => { 'pmtpa' => [ 'db37', 'db56', 'db58', 'db68' ],
				'eqiad' => [ 'db1007', 'db1024', 'db1028', 'db1041' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "db37", 'eqiad' => "db1041" },
			'snapshot' => [ "db56", "db1007" ],
			'no_master' => []
		},
		'x1' => {
			'hosts' => { 'pmtpa' => [ 'db36', 'db38' ],
				'eqiad' => [ 'db1029', 'db1030', 'db1031' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "db38", 'eqiad' => "db1029" },
			'snapshot' => [ "db1031" ],
			'no_master' => []
		},
		'm1' => {
			'hosts' => { 'pmtpa' => [ 'db33', 'db35' ],
				'eqiad' => ['db1001', 'db1016'] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "db35", 'eqiad' => "db1001" },
			'snapshot' => ["db1016", "db33"],
			'no_master' => []
		},
		'm2' => {
			'hosts' => { 'pmtpa' => [ 'db48', 'db49' ],
				'eqiad' => [ 'db1046', 'db1048' ] },
			'primary_site' => "both",
			'masters' => { 'pmtpa' => "db48", 'eqiad' => "db1048" },
			'snapshot' => [ "db49", "db1046" ],
			'no_master' => []
		},
		'es1' => {
			'hosts' => { 'pmtpa' => [ 'es1', 'es2', 'es3', 'es4' ],
				'eqiad' => [ 'es1001', 'es1002', 'es1003', 'es1004' ] },
			'primary_site' => false,
			'masters' => {},
			'snapshot' => [],
			'no_master' => []
		},
		'es2' => {
			'hosts' => { 'pmtpa' => [ 'es5', 'es6', 'es7' ],
				'eqiad' => [ 'es1005', 'es1006', 'es1007' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "es5", 'eqiad' => "es1005" },
			'snapshot' => [ "es7", "es1007" ],
			'no_master' => []
		},
		'es3' => {
			'hosts' => { 'pmtpa' => [ 'es8', 'es9', 'es10' ],
				'eqiad' => [ 'es1008', 'es1009', 'es1010' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "es8", 'eqiad' => "es1008" },
			'snapshot' => [ "es10", "es1010" ],
			'no_master' => []
		},
		'fundraisingdb' => {
			'hosts' => { 'pmtpa' => [ 'db78' ],
				'eqiad' => ['db1008', 'db1013'] },
			'primary_site' => $::mw_primary,
			'masters' => { 'eqiad' => "db1008" },
			'snapshot' => [],
			'no_master' => []
		},
	}
}

class role::coredb::s1( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s1",
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
		innodb_log_file_size => "2000M"
	}
}

class role::coredb::s2( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s2",
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
		innodb_log_file_size => "2000M"
	}
}

class role::coredb::s3( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s3",
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
	}
}

class role::coredb::s4( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s4",
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
		innodb_log_file_size => "2000M"
	}
}

class role::coredb::s5( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s5",
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
		innodb_log_file_size => "1000M"
	}
}

class role::coredb::s6( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s6",
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
	}
}

class role::coredb::s7( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s7",
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
	}
}

class role::coredb::x1( $mariadb = true ) {
	class { "role::coredb::common":
		shard => "x1",
		mariadb => $mariadb,
		innodb_file_per_table => true,
	}
}

class role::coredb::m1( $mariadb = false ) {
	class { "role::coredb::common":
		shard => "m1",
		mariadb => $mariadb,
		innodb_file_per_table => true,
	}
}

class role::coredb::m2( $mariadb = false ) {
	class { "role::coredb::common":
		shard => "m2",
		mariadb => $mariadb,
		innodb_file_per_table => true,
		skip_name_resolve => false,
		mysql_max_allowed_packet => 1073741824,
	}
}

class role::coredb::es1( $mariadb = false ) {
	class { "role::coredb::common":
		shard => "es1",
		mariadb => $mariadb,
		innodb_file_per_table => true,
		slow_query_digest => false,
		heartbeat_enabled => false,
	}
}

class role::coredb::es2( $mariadb = false ) {
	class { "role::coredb::common":
		shard => "es2",
		mariadb => $mariadb,
		innodb_file_per_table => true,
		slow_query_digest => false,
	}
}

class role::coredb::es3( $mariadb = false ) {
	class { "role::coredb::common":
		shard => "es3",
		mariadb => $mariadb,
		innodb_file_per_table => true,
		slow_query_digest => false,
	}
}

class role::coredb::researchdb( $shard="s1", $innodb_log_file_size = "2000M", $mariadb = false, $innodb_file_per_table = false ){
	class { "role::coredb::common":
		shard => $shard,
		mariadb => $mariadb,
		innodb_log_file_size => $innodb_log_file_size,
		read_only => false,
		disable_binlogs => true,
		long_timeouts => true,
		enable_unsafe_locks => true,
		large_slave_trans_retries => true,
		innodb_file_per_table => $innodb_file_per_table
	}
}

class role::coredb::fundraising( $mariadb = true ) {
	class { "role::coredb::common":
		shard => "fundraisingdb",
		logical_cluster => "fundraising",
		mariadb => $mariadb,
		innodb_file_per_table => true,
		slow_query_digest => false,
		heartbeat_enabled => false
	}
}

class role::coredb::common(
	$shard,
	$logical_cluster = "mysql",
	$mariadb,
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
	$heartbeat_enabled = true,
	) inherits role::coredb::config {

	$cluster = $logical_cluster
	$primary_site = $topology[$shard]['primary_site']
	$masters = $topology[$shard]['masters']
	$snapshots = $topology[$shard]['snapshot']

	system_role { "dbcore": description => "Shard ${shard} Core Database server" }

	include standard,
		mysql_wmf::coredb::ganglia,
		mha::node,
		cpufrequtils

	if $masters[$::site] == $::hostname
		and ( $primary_site == $::site or $primary_site == 'both' ){
		class { "coredb_mysql":
			shard => $shard,
			mariadb => $mariadb,
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
			heartbeat_enabled => $heartbeat_enabled,
		}

		class { "mysql_wmf::coredb::monitoring": crit => true }

	}
	else {
		class { "coredb_mysql":
			shard => $shard,
			mariadb => $mariadb,
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
			heartbeat_enabled => $heartbeat_enabled,
		}

		if $primary_site {
			class { "mysql_wmf::coredb::monitoring": crit => false }
		} else {
			class { "mysql_wmf::coredb::monitoring": crit => false, no_slave => true }
		}
	}

	if $::hostname in $snapshots {
		include coredb_mysql::snapshot
	}
}
