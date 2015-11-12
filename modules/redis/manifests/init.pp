class redis {
    require_package('redis-server')

    file { '/srv/redis':
        owner   => 'redis',
        group   => 'redis',
        mode    => '0755',
    }
}
