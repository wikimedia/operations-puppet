# SPDX-License-Identifier: Apache-2.0
class profile::idp::memcached (
    Wmflib::Ensure      $ensure           = lookup('profile::idp::memcached::ensure'),
    Array[Stdlib::Host] $idp_nodes        = lookup('profile::idp::memcached::idp_nodes'),
    String[1]           $mcrouter_cluster = lookup('profile::idp::memcached::mcrouter_cluster'),
    String              $memcached_user   = lookup('profile::idp::memcached::memcached_user'),
    Boolean             $enable_tls       = lookup('profile::idp::memcached::enable_tls'),
    Stdlib::Unixpath    $ssl_cert         = lookup('profile::idp::memcached::ssl_cert'),
    Stdlib::Unixpath    $ssl_key          = lookup('profile::idp::memcached::ssl_key'),
    Boolean             $auto_restarts    = lookup('profile::idp::memcached::auto_restarts'),
) {
    class { 'memcached':
        enable_tls     => $enable_tls,
        ssl_cert       => $ssl_cert,
        ssl_key        => $ssl_key,
        memcached_user => $memcached_user,
    }
    class { 'profile::prometheus::memcached_exporter': }

    $servers = $idp_nodes.map |Stdlib::Host $host| {
        ($host == $facts['fqdn']) ? {
            true    => "127.0.0.1:${memcached::port}:ascii:plain",
            default => "${host.ipresolve}:${memcached::port}:ascii:ssl",
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

    class {'mcrouter':
        ensure  => $ensure,
        region  => $::site,
        cluster => $mcrouter_cluster,
        pools   => $pools,
        routes  => $routes,
    }
    class {'profile::prometheus::mcrouter_exporter':
        mcrouter_port => $mcrouter::port,
    }

    firewall::service {'memcached':
        ensure  => $ensure,
        proto   => 'tcp',
        notrack => true,
        port    => $memcached::port,
        srange  => $apereo_cas::idp_nodes,
    }

    if $auto_restarts {
        profile::auto_restarts::service { 'mcrouter': }
        profile::auto_restarts::service { 'memcached': }
    }
}
