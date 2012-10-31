# application server base class
class redis (
	$port = 6379,
	$name = "redis",
	$dir = "/a/redis",
	$dbfilename = "dump.rdb",
	$maxmemory = "1GB",
	$maxmemory_policy = "volatile-lru",
	$maxmemory_samples = 5,
	$redis_options = {},
	$package = "redis-server",
	$package_version = "2.6.0-rc7-wmf1",
) {
	case $::operatingsystem {
		debian, ubuntu: {
		}
		default: {
			fail("Module ${module_name} is not supported on ${::operatingsystem}")
		}
	}

	package { 'redis':
		name => $package,
		ensure => $package_version;
	}

	file { "$dir":
		ensure => directory,
		owner => 'redis',
		group => 'redis',
		mode => 0755,
		require => Package['redis'];
	}

	file { '/etc/redis/redis.conf':
		content => template('redis/redis.conf.erb'),
		mode => 0444,
		owner => 'root',
		group => 'root',
		require => Package['redis'];
	}

	service { 'redis':
		enabled => true,
		ensure => running,
		require => File['/etc/redis/redis.conf'];
		# subscribe => not doing this deliberately
	}
}
