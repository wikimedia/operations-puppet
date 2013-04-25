class ganglia_new::monitor::packages {
	if !defined(Package["ganglia-monitor"]) {
		package { "ganglia-monitor": ensure => latest }
	}

	file { "/usr/lib/ganglia/python_modules":
		require => Package["ganglia-monitor"],
		ensure => directory
	}
}
