
# Virtual resource for monitoring server
@monitor_group { "memcached_pmtpa": description => "pmtpa memcached" }
@monitor_group { "memcached_eqiad": description => "eqiad memcached" }

class role::memcached {

	$cluster = "memcached"

	system_role { "role::memcached": description => "memcached server" }

	include standard,
		generic::sysctl::high-http-performance

	class { "::memcached":
		memcached_size => '89088',
		memcached_port => '11211',
		version => '1.4.15-0wmf1',
		memcached_options => {
			'-o' => 'slab_reassign',
			'-D' => ':',
		}
	}

}
