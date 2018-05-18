# Class profile::mcrouter_backend
#
# Configures a mcrouter instance using a local memcached server
class profile::mcrouter_backend(
    Integer $lport = hiera('profile::mcrouter_backend::listen_port'),
    Integer $mcport = hiera('profile::mcrouter_backend::mc_port')
) {
    $pools = { 'local' => { 'servers' => [ "127.0.0.1:${mcport}" ] } }
    $routes = [ { 'aliases' => [ '/local/mc/' ], 'route' => 'PoolRoute|local' } ]

    class { '::mcrouter':
        pools                    => $pools,
        routes                   => $routes,
        region                   => 'local',
        cluster                  => 'mc',
        cross_region_timeout_ms  => 250,
        cross_cluster_timeout_ms => 1000,
        port                     => $lport
    }

    class { '::mcrouter::monitoring': }

    ferm::rule { 'skip_mcrouter_wancache_conntrack_out':
        desc  => 'Skip outgoing connection tracking for mcrouter',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => "proto tcp sport (${lport}) NOTRACK;",
    }

    ferm::rule { 'skip_mcrouter_wancache_conntrack_in':
        desc  => 'Skip incoming connection tracking for mcrouter',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => "proto tcp dport (${lport}) NOTRACK;",
    }
}
