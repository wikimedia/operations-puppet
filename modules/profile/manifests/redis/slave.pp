class profile::redis::slave(
    $settings = hiera('profile::redis::slave::settings'),
    $master = hiera('profile::redis::slave::master'),
    $aof = hiera('profile::redis::slave::aof', false),
){
    # Figure out the redis instances running on the master from Puppetdb
    $resources = query_resources(
        "fqdn='${master}'",
        'Redis::Instance', false)
    $password = $resources[0]['parameters']['settings']['requirepass']
    $redis_ports = inline_template("<%= @resources.map{|r| r['title']}.join ' ' -%>")
    $instances = split($redis_ports, ' ')
    $uris = apply_format("localhost:%s/${password}", $instances)

    system::role {'profile::redis::slave': }
    $auth_settings = {
        'masterauth'  => $password,
        'requirepass' => $password,
    }

    $slaveof = ipresolve($master, 4)

    profile::redis::instance{ $instances:
        settings => merge($auth_settings, $settings),
        slaveof  => $slaveof,
        aof      => true,
    }

    # Add monitoring, using nrpe and not remote checks anymore
    redis::monitoring::nrpe_instance { $instances: }

    diamond::collector { 'Redis':
        settings => { instances => join($uris, ', ') }
    }

    ferm::service { 'redis_slave_role':
        proto   => 'tcp',
        notrack => true,
        port    => inline_template('(<%= @redis_ports %>)'),
    }

}
