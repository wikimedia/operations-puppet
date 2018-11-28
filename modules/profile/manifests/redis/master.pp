class profile::redis::master(
    $instances = hiera('profile::redis::master::instances'),
    $settings = hiera('profile::redis::master::settings'),
    $password = hiera('profile::redis::master::password'),
    $aof = hiera('profile::redis::master::aof', false),
    $clients = hiera('profile::redis::master::clients', []),
    $prometheus_nodes = hiera('prometheus_nodes'),
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
