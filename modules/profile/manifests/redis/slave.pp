# SPDX-License-Identifier: Apache-2.0
class profile::redis::slave(
    Optional[Hash] $settings = lookup('profile::redis::slave::settings'),
    Hash $instance_overrides = lookup('profile::redis::slave::instance_overrides', {'default_value' => {}}),
    Stdlib::Host $master = lookup('profile::redis::slave::master'),
    Boolean $aof = lookup('profile::redis::slave::aof', {'default_value' => false}),
){
    # Figure out the redis instances running on the master from Puppetdb
    $pql = "resources[certname, parameters, title] { certname = \"${master}\" and type = \"Redis::Instance\" }"
    $resources = wmflib::puppetdb_query($pql)

    # TODO: T228266, this is a not so temporary workaround
    if $resources.empty {
        # Only PCC should hit this, but at least be explicit
        $password = ''
    } else {
        $password = $resources[0].dig('parameters', 'settings', 'requirepass').lest || { '' }
    }
    # TODO: T228266 is properly resolved, $instances will probably be 0 in
    # PCC for some hosts
    $instances = $resources.map |$r| { $r['title'] }
    $uris = $instances.map |$instance| { "localhost:${instance}/${password}" }

    $auth_settings = {
        'masterauth'  => $password,
        'requirepass' => $password,
    }

    $slaveof = ipresolve($master, 4)

    $instances.each |String $instance| {
        $override = $instance_overrides[$instance].lest || { {} }
        profile::redis::instance { $instance:
            settings => merge($settings, $auth_settings, $override),
            slaveof  => $slaveof,
            aof      => $aof,
        }
    }

    # Add monitoring, using nrpe and not remote checks anymore
    redis::monitoring::nrpe_instance { $instances: }

    profile::prometheus::redis_exporter{ $instances:
        password => $password,
    }

    ferm::service { 'redis_slave_role':
        proto   => 'tcp',
        notrack => true,
        port    => $instances.map |$x| { Integer($x) },
    }
}
