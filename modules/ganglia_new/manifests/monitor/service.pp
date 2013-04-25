class ganglia_new::monitor::service() {
	Class[ganglia_new::monitor::config] -> Class[ganglia_new::monitor::service]

	file { "/etc/init/ganglia-monitor.conf":
		source => "puppet:///modules/$module_name/upstart/ganglia-monitor.conf",
		mode => 0444
	}

	upstart_job { "ganglia-monitor": }

	service { "ganglia-monitor":
		require => File["/etc/init/ganglia-monitor.conf"],
		alias => "gmond",
		ensure => running,
		provider => upstart
	}
}
