class ganglia::monitor::packages {
	package { "ganglia-monitor": ensure => latest }
	
	file { "/etc/init/ganglia-monitor.conf":
		source => "puppet:///modules/ganglia/upstart/ganglia-monitor.conf",
		mode => 0444
	}
	
	upstart_job { "ganglia-monitor": }
}
