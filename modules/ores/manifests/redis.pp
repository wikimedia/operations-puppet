class ores::redis(
    $maxmemory
) {
    redis::instance { '6379':
        settings => {
            dir            => '/srv/redis',
            maxmemory      => $maxmemory,
            appendonly     => 'yes',
            appendfilename => "${hostname}-6379.aof",
            tcp_keepalive  => 60,
        }
    }
}
