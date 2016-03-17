# A class to install and configure redis in the ORES environment
class ores::redis(
    $queue_maxmemory,
    $cache_maxmemory,
) {
    file { [
        '/srv/redis/queue',
        '/srv/redis/cache'
        ]:
        ensure => directory,
        owner  => 'redis',
        group  => 'redis',
        mode   => '0774'
    }

    # FIXME: Tune the individual redises better for their use case
    # queue: 6379, cache: 6380
    redis::instance { ['6379', '6380']:
        # lint:ignore:arrow_alignment
        settings => {
            bind          => '0.0.0.0',
            tcp_keepalive => 60,
        },
        map => {
            '6379' => {
                dir       => '/srv/redis/queue',
                maxmemory => $queue_maxmemory,
            },
            '6380' => {
                dir       => '/srv/redis/cache',
                maxmemory => $cache_maxmemory,
            },
        },
        require => [
            File['/srv/redis/queue'],
            File['/srv/redis/cache'],
        ],
        # lint:endignore
    }
}
