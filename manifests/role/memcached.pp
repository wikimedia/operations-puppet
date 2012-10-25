
# Virtual resource for monitoring server
@monitor_group { "memcached_pmtpa": description => "pmtpa memcached" }
@monitor_group { "memcached_eqiad": description => "pmtpa memcached" }

class role::memcached {

	$cluster = "memcached"

	system_role { "role::memcached": description => "memcached server" }

	include standard,
		generic::sysctl::high-http-performance

	class { "::memcached":
		memcached_size => '89088',
		memcached_port => '11211',
		memcached_options => {
			'-o' => 'slab_reassign',
			'-D' => ':',
		}
	}

}
