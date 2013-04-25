class ganglia_new::monitor::aggregator($sites) {
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

	upstart_job { "ganglia-monitor-aggregator-instance": }

	define site_instances() {
		# Instantiate aggregators for all clusters for this site ($title)
		$cluster_list = suffix(keys($ganglia_new::configuration::clusters), "_${title}")
		instance{ $cluster_list: site => $title }
	}

	site_instances{ $sites: }

	service { "ganglia-monitor-aggregator":
		provider => upstart,
		name => "ganglia-monitor-aggregator",
		ensure => running
	}
}
