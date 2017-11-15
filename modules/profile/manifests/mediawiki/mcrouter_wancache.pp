# Class profile::mcrouter_wancache
#
# Configures a mcrouter instance for multi-datacenter caching
class profile::mediawiki::mcrouter_wancache(
    Hash $servers_by_datacenter_category = hiera('mcrouter::shards'),
    Integer $port = hiera('profile::mediawiki::mcrouter_wancache::port')
) {
    $servers_by_datacenter = $servers_by_datacenter_category['wancache']

    $pool_configs = $servers_by_datacenter.map |$region, $servers| {
        {
            $servers_ = $servers # https://github.com/rodjek/puppet-lint/issues/464
            $region => {
                'servers' => $servers_.map |$shard_slot, $address| {
                    "${address['host']}:${address['port']}"
                }
            }
        }
    }
    $pools = $pool_configs.reduce |$memo, $value| {
        $memo + $value
    }

    $routes = union(
        $servers_by_datacenter.map |$region, $servers| {
            {
                'aliases' => [ "/${region}/mw/" ],
                'route'   => "PoolRoute|${region}"
            }
        },
        $servers_by_datacenter.map |$region, $servers| {
            {
                'aliases' => [ "/${region}/mw-wan/" ],
                'route'   => {
                    'type'           => 'OperationSelectorRoute',
                    'default_policy' => "PoolRoute|${region}",
                    'operation_policies' => {
                        'set'    => "AllFastestRoute|Pool|${region}",
                        'delete' => "AllFastestRoute|Pool|${region}"
                    }
                }
            }
        }
    )

    class { '::mcrouter':
        pools                    => $pools,
        routes                   => $routes,
        region                   => $::site,
        cluster                  => 'mw',
        cross_region_timeout_ms  => 250,
        cross_cluster_timeout_ms => 1000,
        port                     => $port
    }

    class { '::mcrouter::monitoring': }

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
