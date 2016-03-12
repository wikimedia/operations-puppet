class role::jobqueue_redis {
    include ::standard
    include ::passwords::redis

    system::role { 'role::jobqueue_redis': }

    $password = $passwords::redis::main_password
    $slaveof = hiera('jobqueue_redis_slaveof', undef)
    $shards = hiera('redis::shards')

    if ($slaveof == undef) { # Local master
        $ip = $::main_ipaddress
        $instances = redis_get_instances($ip, $shards)
        # find out the replication topology
        $replica_map = redis_add_replica({}, $ip, $shards, $::mw_primary)

        # Encrypt the replication
        if os_version('Debian >= jessie') {
            class { 'redis::multidc::ipsec':
                shards => $shards
            }
        }
        mediawiki::jobqueue_redis {$instances: slaveof => $replica_map}
    } else {
        # Slave: the slave has the same instances as its master
        $instances = redis_get_instances($slaveof, $shards)
        mediawiki::jobqueue_redis { $instances: slaveof => $slaveof}
    }

    $uris = apply_format("localhost:%s/${password}", $instances)
    diamond::collector { 'Redis':
        settings => { instances => join($uris, ', ') }
    }
}
