# memcached.pp

# Virtual resource for monitoring server
@monitor_group { "mc_pmtpa": description => "pmtpa memcached" }

class memcached {

	include memcached::config

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
		monitor_service { "memcached": description => "Memcached", check_command => "check_tcp!11000" }

		# Ganglia
		package { python-memcache:
			ensure => absent;
		}

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

class memcached::config {

	file {
		"/etc/memcached.conf":
			source => "puppet:///files/memcached/memcached.conf",
			owner => root,
			group => root,
			mode => 0644;
	}

}

class memcached::disabled {

	package { memcached:
		ensure => absent;
	}

        service { memcached:
                require => Package[memcached],
		enable     => false,
                ensure => stopped;
        }
}
