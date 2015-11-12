class ores::redis(
    $maxmemory
) {
    class { '::redis::legacy':
        maxmemory => $maxmemory,
        redis_options  => {
            'tcp-keepalive' => 60,
        }
    }
}
