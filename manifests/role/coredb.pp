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
			'hosts' => { 'pmtpa' => [ 'db63' ],
				'eqiad' => [ 'db1037', 'db1043', 'db1049', 'db1050', 'db1051', 'db1052', 'db1055', 'db1056', 'db1061', 'db1062' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "db63", 'eqiad' => 'db1052' },
			'snapshot' => [ 'db1050' ],
			'no_master' => [ 'db1047', 'db1050', 'db1055' ]
		},
		's2' => {
			'hosts' => { 'pmtpa' => [ 'db69' ],
				'eqiad' => [ 'db1002', 'db1009', 'db1018', 'db1024', 'db1034', 'db1036', 'db1060', 'db1063' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => 'db69', 'eqiad' => 'db1024' },
			'snapshot' => [ 'db1018' ],
			'no_master' => [ 'db1002', 'db1018' ]
		},
		's3' => {
			'hosts' => { 'pmtpa' => [ 'db71' ],
				'eqiad' => [ 'db1003', 'db1019', 'db1027', 'db1035', 'db1038' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => 'db71', 'eqiad' => 'db1038' },
			'snapshot' => [ 'db1035' ],
			'no_master' => [ 'db1003', 'db1035' ]
		},
		's4' => {
			'hosts' => { 'pmtpa' => [ 'db72' ],
				'eqiad' => [ 'db1004', 'db1011', 'db1020', 'db1040', 'db1042', 'db1059' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => 'db72', 'eqiad' => 'db1040' },
			'snapshot' => [ 'db1042' ],
			'no_master' => [ 'db1004', 'db1042' ]
		},
		's5' => {
			'hosts' => { 'pmtpa' => [ 'db73' ],
				'eqiad' => [ 'db1005', 'db1021', 'db1026', 'db1045', 'db1058' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => 'db73', 'eqiad' => 'db1058' },
			'snapshot' => [ 'db1005' ],
			'no_master' => [ 'db1005', 'db1026' ]
		},
		's6' => {
			'hosts' => { 'pmtpa' => [ 'db74' ],
				'eqiad' => [ 'db1006', 'db1010', 'db1015', 'db1022', 'db1023' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => 'db74', 'eqiad' => 'db1023' },
			'snapshot' => [ 'db1022' ],
			'no_master' => [ 'db1022', 'db1010' ]
		},
		's7' => {
			'hosts' => { 'pmtpa' => [ 'db68' ],
				'eqiad' => [ 'db1007', 'db1033', 'db1028', 'db1039', 'db1041' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => 'db68', 'eqiad' => 'db1033' },
			'snapshot' => [ 'db1007' ],
			'no_master' => [ 'db1007', 'db1041' ]
		},
		'x1' => {
			'hosts' => {
				'eqiad' => [ 'db1029', 'db1030', 'db1031' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'eqiad' => 'db1029' },
			'snapshot' => [ 'db1031' ],
			'no_master' => []
		},
		'm1' => {
			'hosts' => {
				'eqiad' => ['db1001', 'db1016'] },
			'primary_site' => $::mw_primary,
			'masters' => { 'eqiad' => 'db1001' },
			'snapshot' => ['db1016' ],
			'no_master' => []
		},
		'm2' => {
			'hosts' => {
				'eqiad' => [ 'db1046', 'db1048' ] },
			'primary_site' => 'both',
			'masters' => { 'eqiad' => 'db1048' },
			'snapshot' => [ 'db1046' ],
			'no_master' => []
		},
		'es1' => {
			'hosts' => { 'pmtpa' => [ 'es4' ],
				'eqiad' => [ 'es1001', 'es1002', 'es1003', 'es1004' ] },
			'primary_site' => false,
			'masters' => {},
			'snapshot' => [],
			'no_master' => []
		},
		'es2' => {
			'hosts' => { 'pmtpa' => [ 'es7' ],
				'eqiad' => [ 'es1005', 'es1006', 'es1007' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => "es7", 'eqiad' => "es1005" },
			'snapshot' => [ 'es1007' ],
			'no_master' => []
		},
		'es3' => {
			'hosts' => { 'pmtpa' => [ 'es8' ],
				'eqiad' => [ 'es1008', 'es1009', 'es1010' ] },
			'primary_site' => $::mw_primary,
			'masters' => { 'pmtpa' => 'es8', 'eqiad' => 'es1008' },
			'snapshot' => [ 'es1010' ],
			'no_master' => []
		},
	}
}

class role::coredb::s1( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s1",
		slow_query_digest => false,
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
		innodb_log_file_size => "2000M"
	}
}

class role::coredb::s2( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s2",
		slow_query_digest => false,
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
		innodb_log_file_size => "2000M"
	}
}

class role::coredb::s3( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s3",
		slow_query_digest => false,
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
	}
}

class role::coredb::s4( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s4",
		slow_query_digest => false,
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
		innodb_log_file_size => "2000M"
	}
}

class role::coredb::s5( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s5",
		slow_query_digest => false,
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
		innodb_log_file_size => "1000M"
	}
}

class role::coredb::s6( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s6",
		slow_query_digest => false,
		mariadb => $mariadb,
		innodb_file_per_table => $innodb_file_per_table,
	}
}

class role::coredb::s7( $mariadb = false, $innodb_file_per_table = false ) {
	class { "role::coredb::common":
		shard => "s7",
		slow_query_digest => false,
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
		innodb_file_per_table => $innodb_file_per_table,
		# send researchdb icinga alerts to admins
		# and analytics icinga contact groups.
		contact_group => 'admins,analytics',
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
	$contact_group = 'admins',
	) inherits role::coredb::config {

	$cluster = $logical_cluster
	$primary_site = $topology[$shard]['primary_site']
	$masters = $topology[$shard]['masters']
	$snapshots = $topology[$shard]['snapshot']

	system::role { "dbcore": description => "Shard ${shard} Core Database server" }

	include standard,
		mha::node,
		cpufrequtils
	class { 'mysql_wmf::coredb::ganglia' : mariadb => $mariadb; }

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

		class { "mysql_wmf::coredb::monitoring":
			crit          => true,
			contact_group => $contact_group,
		}

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
