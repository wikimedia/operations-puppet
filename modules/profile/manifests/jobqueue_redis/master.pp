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

    profile::multidc_redis::instances{ $instances:
        ip        => $ip,
        shards    => $shards,
        discovery => 'appservers-rw',
        aof       => true,
        settings  => {
            bind                        => '0.0.0.0',
            appendonly                  => true,
            auto_aof_rewrite_min_size   => '512mb',
            client_output_buffer_limit  => 'slave 2048mb 512mb 60',
            dir                         => '/srv/redis',
            masterauth                  => $passwords::redis::main_password,
            maxmemory                   => '8Gb',
            no_appendfsync_on_rewrite   => true,
            requirepass                 => $passwords::redis::main_password,
            save                        => '""',
            stop_writes_on_bgsave_error => false,
            slave_read_only             => false,
        },
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
