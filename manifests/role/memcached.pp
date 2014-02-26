# vim: noet

# Virtual resource for monitoring server
@monitor_group { "memcached_pmtpa": description => "pmtpa memcached" }
@monitor_group { "memcached_eqiad": description => "eqiad memcached" }

class role::memcached {

	$cluster = "memcached"

	system::role { "role::memcached": description => "memcached server" }

	include standard,
		webserver::base

	$memcached_size = $::realm ? {
		'production' => '89088',
		'labs'       => '3000',
	}

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
