# == Class: redis
#
# Redis is an in-memory data store with support for rich data structures,
# scripting, transactions, persistence, and high availability.
#
class redis {
    require_package('redis-server')

    file { '/srv/redis':
        ensure => directory,
        owner  => 'redis',
        group  => 'redis',
        mode   => '0755',
    } -> Redis::Instance <| |>

    # Disable the default, system-global redis service,
    # because it's incompatible with a multi-instance setup.
    service { 'redis-server':
        ensure    => stopped,
        enable    => false,
        subscribe => Package['redis-server'],
    }
}
