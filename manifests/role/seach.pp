class role::lucene::indexer {
	$roles += [ 'search::indexer' ]
	$cluster = "search"
	$nagios_group = "lucene"

	include standard,
		admins::roots,
		admins::mortals,
		admins::restricted,
		lucene::sudo

	class { lucene::server:
		indexer => "true", udplogging => "false"
	}
}

class role::lucene::client-server {
	$roles += [ 'search' ]
	$cluster = "search"
	$nagios_group = "lucene"

	$lvs_realserver_ips = [ "10.2.1.11", "10.2.1.12", "10.2.1.13" ]

	include standard,
		admins::roots,
		admins::mortals,
		admins::restricted,
		lvs::realserver,
		lucene::sudo

	class { lucene::server:
                udplogging => "false"
	}
}
