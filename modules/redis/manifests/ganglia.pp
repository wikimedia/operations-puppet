class redis::ganglia {
    include redis::legacy

    $password = $redis::legacy::password

    file { '/etc/ganglia/conf.d/redis.pyconf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('redis/redis.pyconf.erb'),
        notify  => Service['ganglia-monitor'],
    }
    file { '/usr/lib/ganglia/python_modules/redis_monitoring.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/redis/ganglia/redis_monitoring.py',
        notify => Service['ganglia-monitor'],
    }
}
