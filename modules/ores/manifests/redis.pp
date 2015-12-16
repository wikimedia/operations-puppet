class ores::redis(
    $maxmemory
) {
    # Uses the default rdb settings, which are good enough
    redis::instance { '6379':
        settings => {
            dir            => '/srv/redis',
            maxmemory      => $maxmemory,
            tcp_keepalive  => 60,
        }
    }
}
