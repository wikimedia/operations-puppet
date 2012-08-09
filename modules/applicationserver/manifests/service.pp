# applicationserver::service

class applicationserver::service {
	Class["applicationserver::packages"] -> Class["applicationserver::service"]

	# Start apache but not at boot
	service { 'apache':
		name => "apache2",
		enable => false,
		ensure => running;
	}

	# Has to be less than apache, and apache has to be nice 0 or less to be
	# blue in ganglia.
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "12.04") >= 0 {
		file { "/etc/init/ssh.override":
			owner => root,
			group => root,
			mode => 0444,
			content => "nice -10",
			ensure => present;
		}
	}
}