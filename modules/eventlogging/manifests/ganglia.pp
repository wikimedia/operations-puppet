# Monitor events per second using Ganglia
class eventlogging::ganglia {

	file { '/usr/lib/ganglia/python_modules/zpubmon.py':
		ensure  => link,
		target  => '/srv/deployment/eventlogging/EventLogging/ganglia/python_modules/zpubmon.py',
		recurse => true,
		require => [
			File['/usr/lib/ganglia/python_modules'],
			Package['python-zmq'],
		],
	}

	file { '/etc/ganglia/conf.d/zpubmon.pyconf':
		ensure   => present,
		recurse  => true,
		source   => 'puppet:///modules/eventlogging/zpubmon.pyconf',
		require  => [
			File['/etc/ganglia/conf.d'],
			File['/usr/lib/ganglia/python_modules/zpubmon.py'],
		],
		notify   => Service[gmond],
	}

}
