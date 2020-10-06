class profile::redis::slave(
    $settings = hiera('profile::redis::slave::settings'),
    $instance_overrides = lookup('profile::redis::slave::instance_overrides', {'default_value' => {}}),
    $master = hiera('profile::redis::slave::master'),
    $aof = hiera('profile::redis::slave::aof', false),
    $prometheus_nodes = hiera('prometheus_nodes'),
){
    # Figure out the redis instances running on the master from Puppetdb
    $resources = query_resources(
        "fqdn='${master}'",
        'Redis::Instance[~".*"]', false)

    # TODO: T228266, this is a not so temporary workaround
    if length($resources) > 0 and has_key($resources[0], 'parameters') and has_key($resources[0]['parameters'], 'settings') {
        $password = $resources[0]['parameters']['settings']['requirepass']
    } else {
        # Only PCC should hit this, but at least be explicit
        $password = ''
    }
    # TODO: T228266 is properly resolved, $instances will probably be 0 in
    # PCC for some hosts
    $redis_ports = inline_template("<%= @resources.map{|r| r['title']}.join ' ' -%>")
    $instances = split($redis_ports, ' ')
    $uris = apply_format("localhost:%s/${password}", $instances)

    $auth_settings = {
        'masterauth'  => $password,
        'requirepass' => $password,
    }

    $slaveof = ipresolve($master, 4)

    $instances.each |String $instance| {
        if $instance in keys($instance_overrides) {
            $override = $instance_overrides[$instance]
        } else {
            $override = {}
        }
        ::profile::redis::instance { $instance:
            settings => merge($settings, $auth_settings, $override),
            slaveof  => $slaveof,
            aof      => $aof,
        }
    }

    # Add monitoring, using nrpe and not remote checks anymore
    redis::monitoring::nrpe_instance { $instances: }

    profile::prometheus::redis_exporter{ $instances:
        password         => $password,
        prometheus_nodes => $prometheus_nodes,
    }

    ferm::service { 'redis_slave_role':
        proto   => 'tcp',
        notrack => true,
        port    => inline_template('(<%= @redis_ports %>)'),
    }
}
