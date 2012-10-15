class role::memcached {

	$nagios_group = "$mc_${::site}"
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
