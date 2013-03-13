class ganglia-new::monitor::service() {
	Class[ganglia-new::monitor::config] -> Class[ganglia-new::monitor::service]

	file { "/etc/init/ganglia-monitor.conf":
		source => "puppet:///modules/ganglia-new/upstart/ganglia-monitor.conf",
		mode => 0444
	}

	upstart_job { "ganglia-monitor": }

	service { "ganglia-monitor":
		require => File["/etc/init/ganglia-monitor.conf"],
		ensure => running,
		provider => upstart
	}
}
