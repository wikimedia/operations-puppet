# vim: noet

# Virtual resource for monitoring server
@monitor_group { "memcached_pmtpa": description => "pmtpa memcached" }
@monitor_group { "memcached_eqiad": description => "eqiad memcached" }

class role::memcached::configuration {

	# memcached -m parameter, the maximum memory in MegaBytes
	$memcached_size = {
		'production' => '89088',
		'labs'       => '15000',
	}

}

class role::memcached {

	$cluster = "memcached"

	system_role { "role::memcached": description => "memcached server" }

	include standard,
		role::memcached::configuration,
		sysctlfile::high-http-performance

	# Look up configuration coming from role::memcached::configuration
	$memcached_size = $role::memcached::configuration::memcached_size[$::realm]

	class { "::memcached":
		memcached_size => $memcached_size,
		memcached_port => '11211',
		version => '1.4.15-0wmf1',
		memcached_options => {
			'-o' => 'slab_reassign',
			'-D' => ':',
		}
	}

}
