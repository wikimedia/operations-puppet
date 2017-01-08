class role::jobqueue_redis {
    include ::standard
    include ::passwords::redis

    system::role { 'role::jobqueue_redis': }

    $password = $passwords::redis::main_password
    $shards = hiera('redis::shards')
    $ip = $::main_ipaddress

    if empty(redis_get_instances($ip, $shards)) {
        # Local slave
        $slaveof = ipresolve(hiera('jobqueue_redis_slaveof'), 4)
        # The instances are the same we'd find on its master
        $instances = redis_get_instances($slaveof, $shards)
        mediawiki::jobqueue_redis { $instances: slaveof => $slaveof}
        # Monitoring
        redis::monitoring::instance { $instances:
            settings => {slaveof => $slaveof},
        }
    } else {
        # Local master
        # Encrypt the replication
        if os_version('Debian >= jessie') {
            class { 'redis::multidc::ipsec':
                shards => $shards,
            }
        }
        $instances = redis_get_instances($ip, $shards)
        # find out the replication topology
        $slaves_map = redis_add_replica({}, $ip, $shards, $::mw_primary)
        mediawiki::jobqueue_redis {$instances: map => $slaves_map}
        # Monitoring
        redis::monitoring::instance { $instances: map => $slaves_map}
    }

    $uris = apply_format("localhost:%s/${password}", $instances)
    diamond::collector { 'Redis':
        settings => { instances => join($uris, ', ') },
    }

    # Firewall rules
    include ::ferm::ipsec_allow

    $redis_ports = join($instances, ' ')

    ferm::service { 'redis_jobqueue_role':
        proto   => 'tcp',
        notrack => true,
        port    => inline_template('(<%= @redis_ports %>)'),
    }

}
