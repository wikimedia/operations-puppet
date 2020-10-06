class profile::redis::master(
    Array[String]       $instances          = lookup('profile::redis::master::instances'),
    Hash                $settings           = lookup('profile::redis::master::settings'),
    Hash                $instance_overrides = lookup('profile::redis::master::instance_overrides',
                                                    {'default_value' => {}}),
    String              $password           = lookup('profile::redis::master::password'),
    Boolean             $aof                = lookup('profile::redis::master::aof',
                                                    {'default_value' => false}),
    Array[String]       $clients            = lookup('profile::redis::master::clients',
                                                    {'default_value' => []}),
    Array[Stdlib::Host] $prometheus_nodes   = lookup('prometheus_nodes'),
){
    $uris = $instances.map |$instance| { "localhost:${instance}/${password}" }
    $redis_ports = join($instances, ' ')

    $auth_settings = {
        'masterauth'  => $password,
        'requirepass' => $password,
    }

    $srange = $clients.empty? {
        true    => undef,
        default => inline_template("@resolve((<%= @clients.join(' ') %>))"),
    }

    $instances.each |String $instance| {
        if $instance in keys($instance_overrides) {
            $override = $instance_overrides[$instance]
        } else {
            $override = {}
        }
        profile::redis::instance { $instance:
            settings => merge($settings, $auth_settings, $override),
            aof      => $aof,
        }
    }

    # Add monitoring, using nrpe and not remote checks anymore
    redis::monitoring::nrpe_instance { $instances: }

    profile::prometheus::redis_exporter{ $instances:
        password         => $password,
        prometheus_nodes => $prometheus_nodes,
    }

    ferm::service { 'redis_master_role':
        proto   => 'tcp',
        notrack => true,
        port    => inline_template('(<%= @redis_ports %>)'),
        srange  => $srange,
    }
}
