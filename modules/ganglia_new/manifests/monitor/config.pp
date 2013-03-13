class ganglia_new::monitor::config($cluster) {
	require ganglia_new::monitor::packages

	$aggregator = false
	$id = $ganglia_new::configuration::clusters[$cluster]['id']
	$portnr = $ganglia_new::configuration::base_port + $id
	$gmond_port = $::realm ? {
		production => $portnr,
		labs => $::project_gid
	}
	$cname = "${cluster} ${::site}"

	file { "/etc/ganglia/gmond.conf":
		mode => 0444,
		content => template("$module_name/gmond.conf.erb"),
		notify => Service["ganglia-monitor"]
	}
}
