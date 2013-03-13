class ganglia::monitor::service() {
	Class[ganglia::monitor::config] -> Class[ganglia::monitor::service]

	service { "ganglia-monitor":
		ensure => running,
		provider => upstart
	}
}
