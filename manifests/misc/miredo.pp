class misc::miredo {

	package { 'miredo':
		ensure => installed;
	}

	file { "/etc/miredo.conf":
		owner => root,
		group => root,
		mode => 0444,
		require => Package['miredo'],
		source => 'puppet:///files/miredo/miredo.conf',
	}

	service { 'miredo':
		ensure => running,
		enabled => true,
		require => Package['miredo'];
	}

}
