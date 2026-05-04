# SPDX-License-Identifier: Apache-2.0
class profile::redis::master(
    Array[Stdlib::Port]      $instances          = lookup('profile::redis::master::instances'),
    Hash                     $settings           = lookup('profile::redis::master::settings'),
    Hash[Stdlib::Port, Hash] $instance_overrides = lookup('profile::redis::master::instance_overrides', {'default_value' => {}}),
    String                   $password           = lookup('profile::redis::master::password'),
    Boolean                  $aof                = lookup('profile::redis::master::aof', {'default_value' => false}),
    Array[Stdlib::Host]      $clients            = lookup('profile::redis::master::clients', {'default_value' => []}),
){
    $uris = $instances.map |$instance| { "localhost:${instance}/${password}" }

    $auth_settings = {
        'masterauth'  => $password,
        'requirepass' => $password,
    }

    $srange = $clients.empty? {
        true    => undef,
        default => inline_template("@resolve((<%= @clients.join(' ') %>))"),
    }

    $instances.each |Stdlib::Port $instance| {
        if $instance in keys($instance_overrides) {
            $override = $instance_overrides[$instance]
        } else {
            $override = {}
        }
        profile::redis::instance { String($instance):
            port     => $instance,
            settings => merge($settings, $auth_settings, $override),
            aof      => $aof,
        }
    }

    $instance_strings = $instances.map |$instance| { String($instance) }

    # Add monitoring, using nrpe and not remote checks anymore
    redis::monitoring::nrpe_instance { $instance_strings: }

    profile::prometheus::redis_exporter{ $instance_strings:
        password => $password,
    }

    if $clients.empty {
        firewall::service { 'redis_master_role':
            proto   => 'tcp',
            notrack => true,
            port    => $instances,
        }
    } else {
        firewall::service { 'redis_master_role':
            proto   => 'tcp',
            notrack => true,
            port    => $instances,
            srange  => $clients,
        }
    }
}
