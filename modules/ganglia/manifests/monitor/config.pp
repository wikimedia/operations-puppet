class ganglia::monitor::config($cluster) {
	require ganglia::monitor::packages

	$aggregator = false
	$id = $ganglia::configuration::clusters[$cluster]['id']
	$gmond_port = $::realm ? {
		production => $ganglia::configuration::base_port + $id,
		labs => $::project_gid
	}

	file { "/etc/ganglia/gmond.conf":
		mode => 0444,
		content => template("ganglia/gmond.conf.erb"),
		notify => Service["ganglia-monitor"]
	}
}
