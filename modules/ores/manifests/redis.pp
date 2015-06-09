class ores::redis(
    $maxmemory
) {
    class { '::redis':
        maxmemory => $maxmemory,
    }
}
