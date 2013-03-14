class ganglia_new::monitor::aggregator {
	require ganglia_new::monitor::packages
	include ganglia_new::configuration

	system_role { "ganglia::monitor::aggregator": description => "central Ganglia aggregator" }

	file {
		"/etc/ganglia/aggregators":
			ensure => directory,
			mode => 0555;
		"/etc/init/ganglia-monitor-aggregator.conf":
			source => "puppet:///modules/$module_name/upstart/ganglia-monitor-aggregator.conf",
			before => Service["ganglia-monitor-aggregator"],
			mode => 0444;
		"/etc/init/ganglia-monitor-aggregator-instance.conf":
			source => "puppet:///modules/$module_name/upstart/ganglia-monitor-aggregator-instance.conf",
			before => Service["ganglia-monitor-aggregator"],
			mode => 0444;
	}

	upstart_job { ["ganglia-monitor-aggregator", "ganglia-monitor-aggregator-instance"]: }

	# Instantiate aggregators for all clusters
	$cluster_list = keys($ganglia_new::configuration::clusters)
	instance{ $cluster_list: }
}
