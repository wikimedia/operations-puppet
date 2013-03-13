class ganglia::monitor::packages {
	if !defined(Package["ganglia-monitor"]) {
		package { "ganglia-monitor": ensure => latest }
	}
}
