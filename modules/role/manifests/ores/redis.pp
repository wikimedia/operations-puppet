# Setting up ORES Redis database in a replicated way in order to facilitate
# failover if required
class role::ores::redis {
    # NOTE: We make this lookup explicit to avoid configuring by mistake a
    # passwordless ores (::ores::redis password parameter defaults to undef)
    $password = hiera('ores::redis::password')
    # We rely on hiera for the slaveof parameter
    class { '::ores::redis':
        queue_maxmemory => '1G',
        cache_maxmemory => '6G',
        password        => $password,
    }
}
