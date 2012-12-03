class coredb_mysql(
	$snapshot,
	$shard,
	$read_only,
	$skip_name_resolve,
	$mysql_myisam,
	$mysql_max_allowed_packet,
	$disable_binlogs,
	$innodb_log_file_size,
	$innodb_file_per_table,
	$long_timeouts,
	$enable_unsafe_locks,
	$large_slave_trans_retries) {

	include coredb_mysql::base,
		coredb_mysql::conf,
		coredb_mysql::heartbeat,
		coredb_mysql::packages,
		coredb_mysql::slow_digest,
		coredb_mysql::utils

	if $snapshot == true {
		include coredb_mysql::snapshot
	}

	Class["coredb_mysql"] -> Class["coredb_mysql::conf"]
}
