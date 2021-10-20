class role::labs::ores::redis {
    class { '::ores::redis':
        queue_maxmemory => '512M',
        cache_maxmemory => '3G',
    }
}
