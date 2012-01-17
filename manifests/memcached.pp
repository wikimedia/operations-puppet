# memcached.pp

# Virtual resource for monitoring server
@monitor_group { "mc_pmtpa": description => "pmtpa memcached" }

class memcached ($memcached_size = '2000', $memcached_port = '11000', $memcached_ip = '0.0.0.0') {

	class { "memcached::config": memcached_size => "$memcached_size", memcached_port => "$memcached_port", memcached_ip => "$memcached_ip" }

	package { memcached:
		ensure => latest;
	}

	service { memcached:
		require => Package[memcached],
		enable     => true,
		ensure => running;
	}

	class monitoring {
		# Nagios
		monitor_service { "memcached": description => "Memcached", check_command => "check_tcp!$memcached_port" }

		# Ganglia
		package { python-memcache:
			ensure => absent;
		}

		# on lucid, this file comes from the ganglia.pp stuff, which
		# means there's actually a hidden dependency on ganglia.pp for
		# the memcache class to work.
		if $lsbdistcodename == "hardy" {
			file {
				"/usr/lib/ganglia/python_modules":
					owner => root,
					group => root,
					mode => 755,
					ensure => directory;
			}
		}
		file {
			"/usr/lib/ganglia/python_modules/memcached.py":
				require => File["/usr/lib/ganglia/python_modules"],
				source => "puppet:///files/ganglia/plugins/memcached.py",
				notify => Service[gmond];
			"/usr/lib/ganglia/python_modules/memcached.pyconf":
				require => File["/usr/lib/ganglia/python_modules"],
				source => "puppet:///files/ganglia/plugins/memcached.pyconf",
				notify => Service[gmond];
		}
	}

	include memcached::monitoring
}

class memcached::config ($memcached_size, $memcached_port, $memcached_ip) {

	file {
		"/etc/memcached.conf":
			content => template("memcached/memcached.conf.erb"),
			owner => root,
			group => root,
			mode => 0644;
	}

}

class memcached::disabled {
	service { memcached:
		enable  => false,
		ensure  => stopped;
	}
}
