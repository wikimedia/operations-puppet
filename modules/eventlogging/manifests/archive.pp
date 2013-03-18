# Configures node to rotate event logs and serve archived logs via rsync
class eventlogging::archive {

	$destinations = [ 'stat1.wikimedia.org' ]

	include rsync::server

	file { [ '/var/log/eventlogging', '/var/log/eventlogging/archive' ]:
		ensure  => directory,
		owner   => 'eventlogging',
		group   => 'wikidev',
		mode    => '0664',
	}

	rsync::server::module { 'eventlogging':
		path        => '/var/log/eventlogging',
		read_only   => 'yes',
		list        => 'yes',
		require     => File['/var/log/eventlogging'],
		hosts_allow => $destinations,
	}

	file { '/etc/logrotate.d/eventlogging':
		source  => 'puppet:///files/eventlogging/logrotate',
		require => File['/var/log/eventlogging/archive'],
		mode    => '0444',
	}

}
