# Use supervisor process management tool (a cousin of upstart and
# daemontools) to start / stop / restart / monitor EventLogging processes.
class eventlogging::supervisor {

	require passwords::mysql::eventlogging  # RT 4752

	package { 'supervisor':
		ensure => present,
	}

	service { 'supervisor':
		ensure  => running,
		enable  => true,
		require => Package['supervisor'],
	}

	file { '/etc/supervisor/supervisord.conf':
		source  => 'puppet:///modules/eventlogging/supervisord.conf',
		require => [ Package['supervisor'], Systemuser['eventlogging'] ],
		notify  => Service['supervisor'],
		mode    => '0444',
	}

	file { '/etc/supervisor/conf.d/eventlogging.conf':
		content => template('eventlogging/eventlogging.conf.erb'),
		require => File['/etc/supervisor/supervisord.conf'],
		notify  => Service['supervisor'],
		mode    => '0444',
	}

}
