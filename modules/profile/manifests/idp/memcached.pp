class profile::idp::memcached (
    Wmflib::Ensure      $ensure           = lookup('profile::idp::memcached::ensure'),
    Array[Stdlib::Host] $idp_nodes        = lookup('profile::idp::memcached::idp_nodes'),
    String[1]           $mcrouter_cluster = lookup('profile::idp::memcached::mcrouter_cluster'),
) {
    $mcrouter_port = 11214
    class { 'memcached':
        # TODO: the following were implicit defaults from
        # MW settings, need to be reviewed.
        growth_factor => 1.05,
        min_slab_size => 5,
    }
    class { 'profile::prometheus::memcached_exporter': }

    $servers = $idp_nodes.map |Stdlib::Host $host| {
        ($host == $facts['fqdn']) ? {
            true    => "127.0.0.1:${memcached::port}:ascii:plain",
            default => "${host.ipresolve}:${mcrouter_port}:ascii:ssl",
        }
    }
    $pools = {$mcrouter_cluster => {'servers' => $servers}}
    $routes = [{
        'aliases' => [ "/${::site}/${mcrouter_cluster}/" ],
        'route'   => {
            'type'               => 'OperationSelectorRoute',
            'default_policy'     => "AllSyncRoute|Pool|${mcrouter_cluster}",
            'operation_policies' => {
                'get'    => "LatestRoute|Pool|${mcrouter_cluster}",
                'add'    => "AllSyncRoute|Pool|${mcrouter_cluster}",
                'delete' => "AllSyncRoute|Pool|${mcrouter_cluster}",
                'set'    => "AllSyncRoute|Pool|${mcrouter_cluster}",
            },
        },
    }]

    base::expose_puppet_certs{'/etc/mcrouter':
        provide_private => true,
        group           => 'mcrouter',
        user            => 'mcrouter',
    }
    $ssl_options = {
        'port'    => 11214,
        'cert'    => '/etc/mcrouter/ssl/cert.pem',
        'key'     => '/etc/mcrouter/ssl/server.key',
        'ca_cert' => $facts['puppet_config']['hostcert'],
    }
    class {'mcrouter':
        ensure      => $ensure,
        region      => $::site,
        cluster     => $mcrouter_cluster,
        pools       => $pools,
        routes      => $routes,
        ssl_options => $ssl_options,
    }
    class {'profile::prometheus::mcrouter_exporter': }

    ferm::service {'mcrouter':
        ensure  => $ensure,
        desc    => 'Allow connections to mcrouter',
        proto   => 'tcp',
        notrack => true,
        port    => $mcrouter_port,
        srange  => "@resolve((${apereo_cas::idp_nodes.join(' ')}))",
    }
}
