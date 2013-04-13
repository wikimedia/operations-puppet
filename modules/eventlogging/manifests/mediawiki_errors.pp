# Monitor MediaWiki errors using Ganglia
class eventlogging::mediawiki_errors {

	file { '/usr/lib/ganglia/python_modules/mwerrors.py':
		ensure  => present,
		source  => 'puppet:///modules/eventlogging/mwerrors.py',
		require => [
			File['/usr/lib/ganglia/python_modules'],
			Package['python-zmq'],
		],
	}

	file { '/etc/supervisor/conf.d/mwerrors.conf':
		source  => 'puppet:///modules/eventlogging/mwerrors.conf',
		require => [ Package['supervisor'], Systemuser['eventlogging'] ],
		notify  => Service['supervisor'],
		mode    => '0444',
	}

	file { '/etc/ganglia/conf.d/mwerrors.pyconf':
		ensure   => present,
		source   => 'puppet:///modules/eventlogging/mwerrors.pyconf',
		require  => [
			File['/etc/ganglia/conf.d'],
			File['/usr/lib/ganglia/python_modules/mwerrors.py'],
			File['/etc/supervisor/conf.d/mwerrors.conf'],
		],
		notify   => Service[gmond],
	}

}
