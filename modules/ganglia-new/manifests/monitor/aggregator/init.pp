class ganglia-new::monitor::aggregator {
	require ganglia-new::monitor::packages

	system_role { "ganglia::monitor::aggregator": description => "central Ganglia aggregator" }

	file {
		"/etc/ganglia/aggregators":
			ensure => directory,
			mode => 0555;
		"/etc/init/ganglia-monitor-aggregator.conf":
			source => "puppet:///modules/ganglia/upstart/ganglia-monitor-aggregator.conf",
			before => Service["ganglia-monitor-aggregator"],
			mode => 0444;
		"/etc/init/ganglia-monitor-aggregator-instance.conf":
			source => "puppet:///modules/ganglia/upstart/ganglia-monitor-aggregator-instance.conf",
			before => Service["ganglia-monitor-aggregator"],
			mode => 0444;
	}

	upstart_job { "ganglia-monitor-aggregator-instance": }

	# Instantiate aggregators for all clusters
	$cluster_list = keys($ganglia-new::configuration::clusters)
	instance{ $cluster_list: }

	service { "ganglia-monitor-aggregator":
		provider => upstart,
		name => "ganglia-monitor-aggregator",
		ensure => running
	}
}
