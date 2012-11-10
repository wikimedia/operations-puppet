class coredb {

	include coredb::base
	include coredb::conf
	include coredb::heartbeat
	include coredb::packages
	include coredb::slow_digest
	include coredb::snapshot
	include coredb::utils
}
