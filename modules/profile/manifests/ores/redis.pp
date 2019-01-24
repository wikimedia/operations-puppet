# Setting up ORES Redis database in a replicated way in order to facilitate
# failover if required
class profile::ores::redis(
    $password = hiera('profile::ores::redis::password'),
    $redis_clients = hiera('profile::ores::redis::client_hosts'),
    $slaveof  = hiera('profile::ores::redis::slaveof', undef),
    $prometheus_nodes = hiera('prometheus_nodes'),
){
    include ::standard
    include ::profile::base::firewall

    $instances = ['6379', '6380']

    class { '::ores::redis':
        password => $password,
        slaveof  => $slaveof,
    }

    ::profile::prometheus::redis_exporter{ $instances:
        password         => $password,
        prometheus_nodes => $prometheus_nodes,
        arguments        => '-check-keys celery',
    }

    $redis_hosts_ferm = join($redis_clients, ' ')
    $redis_ports_ferm = join($instances, ' ')
    ferm::service { 'ores_redis':
        proto  => 'tcp',
        port   => "(${redis_ports_ferm})",
        srange => "@resolve((${redis_hosts_ferm}))",
    }
}
