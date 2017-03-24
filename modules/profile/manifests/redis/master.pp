class profile::redis::master(
    $instances = hiera('profile::redis::master::instances'),
    $settings = hiera('profile::redis::master::settings'),
    $password = hiera('profile::redis::master::password'),
    $aof = hiera('profile::redis::master::aof', false),
){
    $uris = apply_format("localhost:%s/${password}", $instances)
    $redis_ports = join($instances, ' ')

    system::role {'profile::redis::master': }
    $auth_settings = {
        'masterauth'  => $password,
        'requirepass' => $password,
    }

    profile::redis::instance{ $instances:
        settings => merge($settings, $auth_settings),
        aof      => $aof,
    }

    # Add monitoring, using nrpe and not remote checks anymore
    redis::monitoring::nrpe_instance { $instances: }

    diamond::collector { 'Redis':
        settings => { instances => join($uris, ', ') }
    }

    ferm::service { 'redis_master_role':
        proto   => 'tcp',
        notrack => true,
        port    => inline_template('(<%= @redis_ports %>)'),
    }
}
