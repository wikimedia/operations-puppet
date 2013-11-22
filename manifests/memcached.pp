# memcached.pp

class memcached ($memcached_size = '2000', $memcached_port = '11000', $memcached_ip = '0.0.0.0',
		$version = "present", $memcached_options = {}, $pin=false) {

	class { "memcached::config": memcached_size => "$memcached_size", memcached_port => "$memcached_port",
		memcached_ip => "$memcached_ip", memcached_options => $memcached_options }

	if ( $pin ) {
		apt::pin { 'memcached':
			pin      => 'release o=Ubuntu',
			priority => '1001',
			before   => Package['memcached'],
		}
	}

	package { memcached:
		ensure => $version;
	}

	service { memcached:
		require => Package[memcached],
		enable     => true,
		ensure => running;
	}

	# prefer a direct check if memcached is not running on localhost
	# no point in running this over nrpe for e.g. our memcached cluster
	if ($memcached_ip == '127.0.0.1') {
		nrpe::monitor_service { 'memcached':
			description   => 'Memcached',
			nrpe_command  => "/usr/lib/nagios/plugins/check_tcp -H $memcached_ip -p $memcached_port",
		}
	} else {
		monitor_service { 'memcached':
			description   => 'Memcached',
			check_command => "check_tcp!$memcached_port",
		}
	}

	# Ganglia
	package { 'python-memcache':
		ensure => absent,
	}

	# on lucid, /usr/lib/ganglia/python_modules file comes from the ganglia.pp stuff, which
	# means there's actually a hidden dependency on ganglia.pp for
	# the memcache class to work.
	file { '/usr/lib/ganglia/python_modules/memcached.py':
		owner   => 'root',
		group   => 'root',
		mode	=> '0444',
		source  => 'puppet:///files/ganglia/plugins/memcached.py',
		require => File['/usr/lib/ganglia/python_modules'],
		notify  => Service['gmond'],
	}
	file { '/etc/ganglia/conf.d/memcached.pyconf':
		owner   => 'root',
		group   => 'root',
		mode	=> '0444',
		source  => 'puppet:///files/ganglia/plugins/memcached.pyconf',
		require => File['/usr/lib/ganglia/python_modules/memcached.py'],
		notify  => Service['gmond'],
	}
}

class memcached::config ($memcached_size, $memcached_port, $memcached_ip, $memcached_options) {

	file {
		"/etc/memcached.conf":
			content => template("memcached/memcached.conf.erb"),
			owner => root,
			group => root,
			mode => 0644;
		"/etc/default/memcached":
			source => "puppet:///files/memcached/memcached.default",
			owner => root,
			group => root,
			mode => 0444;
	}

}

class memcached::disabled {
	service { memcached:
		enable  => false,
		ensure  => stopped;
	}
}
