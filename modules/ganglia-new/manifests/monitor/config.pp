class ganglia-new::monitor::config($cluster) {
	require ganglia-new::monitor::packages

	$aggregator = false
	$id = $ganglia-new::configuration::clusters[$cluster]['id']
	$portnr = $ganglia-new::configuration::base_port + $id
	$gmond_port = $::realm ? {
		production => $portnr,
		labs => $::project_gid
	}
	$cname = "${cluster} ${::site}"

	file { "/etc/ganglia/gmond.conf":
		mode => 0444,
		content => template("ganglia/gmond.conf.erb"),
		notify => Service["ganglia-monitor"]
	}
}
