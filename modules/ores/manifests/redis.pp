class ores::redis(
    $maxmemory
) {
    class { '::redis':
        maxmemory => $maxmemory,
        redis_options  => {
            'tcp-keepalive' => 60,
        }
    }
}
