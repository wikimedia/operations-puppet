class profile::jobqueue_redis::master(
    $shards = hiera('redis_shards'),
    $conftool_prefix = hiera('conftool_prefix'),
) {
    include ::passwords::redis
    $ip = $facts['ipaddress_primary']
    $instances = redis_get_instances($ip, $shards)
    $password = $passwords::redis::main_password
    $uris = apply_format("localhost:%s/${password}", $instances)
    $redis_ports = join($instances, ' ')

    system::role { 'role::jobqueue_redis::master': }

    # Set up ipsec
    class { 'redis::multidc::ipsec':
        shards => $shards
    }

    class { '::ferm::ipsec_allow': }

    file { '/etc/redis/replica/':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # Now the redis instances. We watch etcd every 5 minutes to fix config
    # based on the mediawiki master datacenter
    class { 'confd':
        interval => 300,
        prefix   => $conftool_prefix,
    }

    profile::jobqueue_redis::instances{ $instances:
        ip     => $ip,
        shards => $shards,
    }

    # Add monitoring, using nrpe and not remote checks anymore
    redis::monitoring::nrpe_instance { $instances: }

    diamond::collector { 'Redis':
        settings => { instances => join($uris, ', ') }
    }

    ferm::service { 'redis_jobqueue_role':
        proto   => 'tcp',
        notrack => true,
        port    => inline_template('(<%= @redis_ports %>)'),
    }
}
