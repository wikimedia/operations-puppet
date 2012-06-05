class misc::miredo {

	package { 'miredo':
		ensure => installed;
	}

	file { "/etc/miredo.conf":
		owner => root,
		group => root,
		mode => 0444,
		require => Package['miredo'],
		source => template('miredo/miredo.conf.erb');
	}

	service { 'miredo':
		ensure => running,
		enabled => true,
		require => Package['miredo'];
	}

}
