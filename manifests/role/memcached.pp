# vim: noet

# Virtual resource for monitoring server
@monitoring::group { 'memcached_eqiad':
    description => 'eqiad memcached',
}

@monitoring::group { 'memcached_codfw':
    description => 'codfw memcached',
}

class role::memcached {
    system::role { 'role::memcached': }

    include standard
    include webserver::sysctl_settings

    $memcached_size = $::realm ? {
        'production' => 89088,
        'labs'       => 3000,
    }

    $version = os_version('debian >= jessie || ubuntu >= trusty') ? {
        true    => 'present',
        default => '1.4.15-0wmf1',
    }

    class { '::memcached':
        size          => $memcached_size,
        port          => 11211,
        version       => $version,
        extra_options => {
            '-o' => 'slab_reassign',
            '-D' => ':',
        }
    }

    package { 'memkeys':
        ensure => present,
    }
}
