# Class profile::mcrouter_wancache
#
# Configures a mcrouter instance for multi-datacenter caching
class profile::mediawiki::mcrouter_wancache(
    $servers_by_datacenter = hiera('mediawiki_wancache_memcached_servers'),
    $cross_region_timeout_ms = hiera('profile::mcrouter_wancache::cross_region_timeout'),
    $cross_cluster_timeout_ms = hiera('profile::mcrouter_wancache::cross_cluster_timeout'),
    $monitor_port = hiera('profile::mcrouter_wancache::monitor_port'), # set to 0 if no port available
) {
    validate_hash($servers_by_datacenter)

    $pools = merge( $servers_by_datacenter.map |$region, $servers| {
        { $region => { 'servers' => $servers } }
    } )

    $route = union(
        $servers_by_datacenter.map |$region, $servers| {
            {
                'aliases' => [ '/' + $region + '/mw/' ],
                'route'   => 'PoolRoute|' + $region
            }
        },
        $servers_by_datacenter.map |$region, $servers| {
            {
                'aliases' => [ '/' + $region + '/mw-wan/' ],
                'route'   => {
                    'type'           => 'OperationSelectorRoute',
                    'default_policy' => 'PoolRoute|' + $region,
                    'operation_policies' => {
                        'set' => 'AllFastestRoute|Pool|' + $region,
                        'delete' => 'AllFastestRoute|Pool|' + $region
                    }
                }
            }
        }
    )

    class { '::mcrouter':
        pools                    => $pools,
        route                    => $route,
        region                   => $::site,
        cluster                  => 'mw',
        cross_region_timeout_ms  => $cross_region_timeout_ms,
        cross_cluster_timeout_ms => $cross_cluster_timeout_ms
    }

    class { '::mcrouter::monitoring':
        port => $monitor_port,
    }

    ferm::rule { 'skip_mcrouter_wancache_conntrack_out':
        desc  => 'Skip outgoing connection tracking for mcrouter',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto tcp sport (6378:6382 11212) NOTRACK;',
    }

    ferm::rule { 'skip_mcrouter_wancache_conntrack_in':
        desc  => 'Skip incoming connection tracking for mcrouter',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto tcp dport (6378:6382 11212) NOTRACK;',
    }
}
