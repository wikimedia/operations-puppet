# Note that the password is looked up at namespace one level up in the hierarchy
# as it is being reused in another profile class in that namespace

class profile::ores::twemproxy (
    $password = hiera('profile::ores::redis_password'),
    $queue_servers = hiera('profile::ores::twemproxy::queue_servers'),
    $cache_servers = hiera('profile::ores::twemproxy::cache_servers'),
){
    $pools = {
        'queue' => {
            auto_eject_hosts     => true,
            distribution         => 'ketama',
            redis                => true,
            redis_auth           => $password,
            hash                 => 'md5',
            listen               => '/var/run/nutcracker/ores_queue.sock 0666',
            server_connections   => 1,
            server_failure_limit => 3,
            server_retry_timeout => to_milliseconds('30s'),
            timeout              => 1000,
            servers              => $queue_servers,
        },
        'cache' => {
            auto_eject_hosts     => true,
            distribution         => 'ketama',
            redis                => true,
            redis_auth           => $password,
            hash                 => 'md5',
            listen               => '/var/run/nutcracker/ores_cache.sock 0666',
            server_connections   => 1,
            server_failure_limit => 3,
            server_retry_timeout => to_milliseconds('30s'),
            timeout              => 1000,
            servers              => $cache_servers,
        }
    }
    class { '::nutcracker':
        pools  => $pools,
    }
}
