# Setting up ORES Redis database in a replicated way in order to facilitate
# failover if required
class profile::ores::redis(
    $password = hiera('profile::ores::redis::password'),
    $redis_clients = hiera('profile::ores::redis::client_hosts'),
    $slaveof  = hiera('profile::ores::redis::slaveof', undef),
){
    include ::standard
    include ::base::firewall

    class { '::ores::redis':
        password => $password,
        slaveof  => $slaveof,
    }

    $redis_hosts_ferm = join($redis_clients, ' ')
    ferm::service { 'ores_redis':
        proto  => 'tcp',
        port   => '(6379 6380)',
        srange => "@resolve((${redis_hosts_ferm}))",
    }
}
