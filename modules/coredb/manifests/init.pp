class coredb($snapshot,
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

	include coredb::base,
		coredb::conf,
		coredb::heartbeat,
		coredb::packages,
		coredb::slow_digest,
		coredb::utils,
		coredb::snapshot

	Class["coredb"] -> Class["coredb::snapshot"]
	Class["coredb"] -> Class["coredb::conf"]
}
