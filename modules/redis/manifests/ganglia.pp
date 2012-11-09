class redis::ganglia {
	file { '/etc/ganglia/conf.d/redis.pyconf':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///modules/redis/ganglia/redis.pyconf',
			notify => Service[gmond];
		'/usr/lib/ganglia/python_modules/redis.py':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///modules/redis/ganglia/redis.py',
			notify => Service[gmond];
	}
}
