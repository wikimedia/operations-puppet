class profile::redis::master(
    $instances = lookup('profile::redis::master::instances'),
    $settings = lookup('profile::redis::master::settings'),
    $password = lookup('profile::redis::master::password'),
    $aof = lookup('profile::redis::master::aof', {'default_value' => false}),
    $clients = lookup('profile::redis::master::clients', {'default_value' => []}),
    $prometheus_nodes = lookup('prometheus_nodes'),
){
    $uris = apply_format("localhost:%s/${password}", $instances)
    $redis_ports = join($instances, ' ')

    $auth_settings = {
        'masterauth'  => $password,
        'requirepass' => $password,
    }

    validate_array($clients)

    if $clients == [] {
        $srange = undef
    } else {
        $srange = inline_template("@resolve((<%= @clients.join(' ') %>))")
    }

    ::profile::redis::instance{ $instances:
        settings => merge($settings, $auth_settings),
        aof      => $aof,
    }

    # Add monitoring, using nrpe and not remote checks anymore
    ::redis::monitoring::nrpe_instance { $instances: }

    ::profile::prometheus::redis_exporter{ $instances:
        password         => $password,
        prometheus_nodes => $prometheus_nodes,
    }

    ::ferm::service { 'redis_master_role':
        proto   => 'tcp',
        notrack => true,
        port    => inline_template('(<%= @redis_ports %>)'),
        srange  => $srange,
    }
}
