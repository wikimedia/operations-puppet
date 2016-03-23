# Setting up ORES Redis database in a replicated way in order to facilitate
# failover if required
class role::ores::redis {
    include ::standard
    include ::base::firewall

    # NOTE: We make this lookup explicit to avoid configuring by mistake a
    # passwordless ores (::ores::redis password parameter defaults to undef)
    $password = hiera('ores::redis::password')
    # We rely on hiera for the slaveof parameter
    class { '::ores::redis':
        password        => $password,
    }

    $redis_clients = hiera('ores::redis::client_hosts')
    $redis_hosts_ferm = join($redis_clients, ' ')
    ferm::service { 'ores_redis':
        proto  => 'tcp',
        port   => '(6379 6380)',
        srange => "@resolve((${redis_hosts_ferm}))",
    }
}
