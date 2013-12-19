# memcached/ganglia.pp

class memcached::ganglia {
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
        mode    => '0444',
        source  => "puppet:///modules/${module_name}/ganglia/memcached.py",
        require => File['/usr/lib/ganglia/python_modules'],
        notify  => Service['gmond'],
    }
    file { '/etc/ganglia/conf.d/memcached.pyconf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/${module_name}/ganglia/memcached.pyconf",
        require => File['/usr/lib/ganglia/python_modules/memcached.py'],
        notify  => Service['gmond'],
    }
}
