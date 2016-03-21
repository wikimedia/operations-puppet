# Setting up ORES Redis database in a replicated way in order to facilitate
# failover if required
class role::ores::redis {
    # We rely on hiera for the slaveof parameter
    class { '::ores::redis':
        queue_maxmemory => '512M',
        cache_maxmemory => '3G',
    }
}
