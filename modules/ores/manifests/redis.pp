class ores::redis(
    $queue_maxmemory,
    $cache_maxmemory,
) {
    file { [
        '/srv/redis',
        '/srv/redis/queue',
        '/srv/redis/cache'
        ]:
        ensure => directory,
        owner  => 'redis',
        group  => 'redis',
        mode   => '0774'
    }

    # FIXME: Tune the individual redises better for their use case
    # For the queue
    redis::instance { '6379':
        settings => {
            dir            => '/srv/redis/queue',
            maxmemory      => $queue_maxmemory,
            tcp_keepalive  => 60,
        },
        require  => File['/srv/redis/queue']
    }

    # For the cache
    redis::instance { '6380':
        settings => {
            dir            => '/srv/redis/cache',
            maxmemory      => $cache_maxmemory,
            tcp_keepalive  => 60,
        },
        require  => File['/srv/redis/cache']
    }
}
