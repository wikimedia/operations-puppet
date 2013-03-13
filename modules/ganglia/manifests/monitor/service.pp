class ganglia::monitor::service() {
	Class[ganglia::monitor::config] -> Class[ganglia::monitor::service]

	file { "/etc/init/ganglia-monitor.conf":
		source => "puppet:///modules/ganglia/upstart/ganglia-monitor.conf",
		mode => 0444
	}

	upstart_job { "ganglia-monitor": }

	service { "ganglia-monitor":
		require => File["/etc/init/ganglia-monitor.conf"],
		ensure => running,
		provider => upstart
	}
}
