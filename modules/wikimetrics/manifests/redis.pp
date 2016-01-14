# == Class: wikimetrics::redis
# Sets up redis for use by wikimetrics queue and scheduler

class wikimetrics::redis(
    $queue_maxmemory = '1Gb',
) {

    file {'/srv/redis/queue':
        ensure => directory,
        owner  => 'redis',
        group  => 'redis',
        mode   => '0774'
    }

    redis::instance { '6379':
        settings => {
            bind           => '0.0.0.0',
            dir            => '/srv/redis/queue',
            maxmemory      => $queue_maxmemory,
            tcp_keepalive  => 60,
        },
        require  => File['/srv/redis/queue']
    }
}
