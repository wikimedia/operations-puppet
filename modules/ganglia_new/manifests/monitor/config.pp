class ganglia_new::monitor::config($cluster) {
	require ganglia_new::monitor::packages
	include ganglia_new::configuration

	$aggregator = false
	$id = $ganglia_new::configuration::clusters[$cluster]['id'] + $ganglia_new::configuration::id_prefix[$::site]
	$desc = $ganglia_new::configuration::clusters[$cluster]['name']
	$portnr = $ganglia_new::configuration::base_port + $id
	$gmond_port = $::realm ? {
		production => $portnr,
		labs => $::project_gid
	}
	$cname = "${desc} ${::site}"

	file { "/etc/ganglia/gmond.conf":
		mode => 0444,
		content => template("$module_name/gmond.conf.erb"),
		notify => Service["ganglia-monitor"]
	}
}
