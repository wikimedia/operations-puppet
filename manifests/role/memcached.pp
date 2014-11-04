# vim: noet

# Virtual resource for monitoring server
@monitor_group { 'memcached_eqiad':
    description => 'eqiad memcached',
}

class role::memcached {
    system::role { 'role::memcached': }

    include standard
    include webserver::sysctl_settings

	$memcached_size = $::realm ? {
		'production' => 89088,
		'labs'       => 3000,
	}

    class { '::memcached':
        size          => $memcached_size,
        port          => 11211,
        version       => '1.4.15-0wmf1',
        extra_options => {
            '-o' => 'slab_reassign',
            '-D' => ':',
        }
    }

    package { 'memkeys':
        ensure => present,
    }
}
