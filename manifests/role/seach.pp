class role::lucene::indexer {
	system_role { "role::lucene::indexer": description => "Lucene search indexer" }
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

class role::lucene::front-end {
	system_role { "role::lucene::front-end": description => "Front end lucene search server" }
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
