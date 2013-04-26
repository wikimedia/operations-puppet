class ganglia_new::monitor::config($gmond_port, $cname, $override_hostname=undef) {
	require ganglia_new::monitor::packages
	include ganglia_new::configuration

	$aggregator = false

	file { "/etc/ganglia/gmond.conf":
		mode => 0444,
		content => template("$module_name/gmond.conf.erb"),
		notify => Service["ganglia-monitor"]
	}
}
