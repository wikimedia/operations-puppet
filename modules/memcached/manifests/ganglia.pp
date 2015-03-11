# memcached/ganglia.pp

class memcached::ganglia {
    # on lucid, /usr/lib/ganglia/python_modules file comes from the ganglia.pp stuff, which
    # means there's actually a hidden dependency on ganglia.pp for
    # the memcache class to work.
    file { '/usr/lib/ganglia/python_modules/memcached.py':
        ensure => 'absent',
    }
    file { '/usr/lib/ganglia/python_modules/gmond_memcached.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/${module_name}/ganglia/gmond_memcached.py",
        require => File['/usr/lib/ganglia/python_modules'],
        notify  => Service['ganglia-monitor'],
    }
    file { '/usr/lib/ganglia/python_modules/memcached.pyconf':
        ensure => 'absent',
    }
    file { '/etc/ganglia/conf.d/gmond_memcached.pyconf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/${module_name}/ganglia/gmond_memcached.pyconf",
        require => File['/usr/lib/ganglia/python_modules/gmond_memcached.py'],
        notify  => Service['ganglia-monitor'],
    }
}
