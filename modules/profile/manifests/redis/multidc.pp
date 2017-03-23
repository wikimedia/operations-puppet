class profile::redis::multidc(
    $category = hiera('profile::redis::multidc::category'),
    $all_shards = hiera('redis::shards'),
    $conftool_prefix = hiera('conftool_prefix'),
    $settings = hiera('profile::redis::multidc::settings'),
    $discovery = hiera('profile::redis::multidc::discovery'),
    $aof = hiera('profile::redis::multidc::aof', false)
) {
    require ::passwords::redis
    $shards = $all_shards[$category]
    $ip = $facts['ipaddress_primary']
    $instances = redis_get_instances($ip, $shards)
    $password = $passwords::redis::main_password
    $uris = apply_format("localhost:%s/${password}", $instances)
    $redis_ports = join($instances, ' ')

    system::role { "profile::redis::${category}": }
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
    # based on the active datacenter for the chosen discovery label
    class { 'confd':
        interval => 300,
        prefix   => $conftool_prefix,
    }

    profile::redis::multidc_instance{ $instances:
        ip        => $ip,
        shards    => $shards,
        discovery => $discovery,
        aof       => $aof,
        settings  => $settings
    }

    # Add monitoring, using nrpe and not remote checks anymore
    redis::monitoring::nrpe_instance { $instances: }

    diamond::collector { 'Redis':
        settings => { instances => join($uris, ', ') }
    }

    ferm::service { "redis_${category}_role":
        proto   => 'tcp',
        notrack => true,
        port    => inline_template('(<%= @redis_ports %>)'),
    }
}
