# == Class: memcached::monitoring
#
# Provisions Ganglia metric-gathering modules for memcached.
#
class memcached::monitoring {
    include ::ganglia

    file { '/usr/lib/ganglia/python_modules/memcached.py':
        source  => 'puppet:///modules/memcached/ganglia/memcached.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => File['/etc/ganglia/conf.d/memcached.pyconf'],
        require => Package['ganglia-monitor'],
        notify  => Service['ganglia-monitor'],
    }

    file { '/etc/ganglia/conf.d/memcached.pyconf':
        source  => 'puppet:///modules/memcached/ganglia/memcached.pyconf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['ganglia-monitor'],
        notify  => Service['ganglia-monitor'],
    }
}
