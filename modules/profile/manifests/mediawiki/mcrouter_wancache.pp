# == Configures a mcrouter instance for multi-datacenter caching
#
# == Properties
#
# [*memcached_tls_port*]
#  TLS port to connect to other memcached servers for cross dc key replication. Check profile::memcached::port
class profile::mediawiki::mcrouter_wancache(
    Stdlib::Port $port                           = lookup('profile::mediawiki::mcrouter_wancache::port'),
    Stdlib::Port $memcached_notls_port           = lookup('profile::mediawiki::mcrouter_wancache::memcached_notls_port'),
    Stdlib::Port $memcached_tls_port             = lookup('profile::mediawiki::mcrouter_wancache::memcached_tls_port'),
    Integer      $num_proxies                    = lookup('profile::mediawiki::mcrouter_wancache::num_proxies'),
    Integer      $timeouts_until_tko             = lookup('profile::mediawiki::mcrouter_wancache::timeouts_until_tko'),
    Integer      $gutter_ttl                     = lookup('profile::mediawiki::mcrouter_wancache::gutter_ttl'),
    Boolean      $prometheus_exporter            = lookup('profile::mediawiki::mcrouter_wancache::prometheus_exporter'),
    Hash         $servers_by_datacenter_category = lookup('profile::mediawiki::mcrouter_wancache::shards')
) {

    $servers_by_datacenter = $servers_by_datacenter_category['wancache']
    $gutters_by_datacenter = $servers_by_datacenter_category['gutter']
    $wikifunctions_servers = $servers_by_datacenter_category['wikifunctions'][$::site]
    # Gutter pools:
    $gutter_pools = $gutters_by_datacenter.map |$dc, $servers| {
        if $dc == $::site {
            profile::mcrouter_pools("${dc}-gutter", $servers, 'plain', $memcached_notls_port)
        } else {
            profile::mcrouter_pools("${dc}-gutter", $servers, 'ssl', $memcached_tls_port)
        }
    }.reduce()|$memo, $value| { $memo + $value }

    # wikifunction pool. We just need the one for the local datacenter.
    # No need for tls here, either, as the traffic is all dc-local.
    $wikifunction_pool = profile::mcrouter_pools("wf-${::site}", $wikifunctions_servers, 'plain', $memcached_notls_port)
    # Server pools
    $pools = $servers_by_datacenter.map |$dc, $servers| {
        if $dc == $::site {
            profile::mcrouter_pools($dc, $servers, 'plain', $memcached_notls_port)
        } else {
            profile::mcrouter_pools($dc, $servers, 'ssl', $memcached_tls_port)
        }
    }.reduce($gutter_pools + $wikifunction_pool) |$memo, $value| { $memo + $value }

    $routes = union(
        # Local cache for each region
        $servers_by_datacenter.map |$dc, $_| {
            $failover_route = $dc ? {
                $::site => true,
                default => false
            };
                {
                    'aliases' => [ "/${dc}/mw/" ],
                    'route' => profile::mcrouter_route($dc, $gutter_ttl, $failover_route)
                }
        },
        # WAN cache: issues reads and add/cas/touch locally and issues set/delete everywhere.
        # MediaWiki will set a prefix of /*/mw-wan when broadcasting, explicitly matching
        # all the mw-wan routes. Broadcasting is thus completely controlled by MediaWiki,
        # but is only allowed for set/delete operations.
        $servers_by_datacenter.map |$dc, $_| {
            $failover_route = true;
            {
                'aliases' => [ "/${dc}/mw-wan/" ],
                'route'   => {
                    'type'               => 'OperationSelectorRoute',
                    'default_policy'     => profile::mcrouter_route($dc, $gutter_ttl, $failover_route),
                    # AllAsyncRoute is used by mcrouter when replicating data to the non-active DC:
                    # https://github.com/facebook/mcrouter/wiki/List-of-Route-Handles#allasyncroute
                    # More info in T225642
                    'operation_policies' => {
                        'set'    => {
                            'type'     => $dc ? {
                                $::site => 'AllSyncRoute',
                                default => 'AllAsyncRoute'
                            },
                            'children' => [ profile::mcrouter_route($dc, $gutter_ttl, $failover_route) ]
                        },
                        'delete' => {
                            'type'     => $dc ? {
                                $::site => 'AllSyncRoute',
                                default => 'AllAsyncRoute'
                            },
                            'children' => [ profile::mcrouter_route($dc, $gutter_ttl, $failover_route) ]
                        },
                    }
                }
            }
        },

        # wikifunctions pool, fully dc-local, no failover.
        [{
            'aliases' => [ '/local/wf/' ],
            'route'   => "PoolRoute|wf-${::site}"
        }]
    )

    class { 'mcrouter':
        pools                  => $pools,
        routes                 => $routes,
        region                 => $::site,
        cluster                => 'mw',
        num_proxies            => $num_proxies,
        timeouts_until_tko     => $timeouts_until_tko,
        probe_delay_initial_ms => 60000,
        port                   => $port,
    }
    file { '/etc/systemd/system/mcrouter.service.d/cpuaccounting-override.conf':
        content => "[Service]\nCPUAccounting=yes\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['systemd daemon-reload for mcrouter.service (mcrouter)']
    }

    ferm::rule { 'skip_mcrouter_wancache_conntrack_out':
        desc  => 'Skip outgoing connection tracking for mcrouter',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => "proto tcp sport (${port} ${memcached_tls_port}) NOTRACK;",
    }

    ferm::rule { 'skip_mcrouter_wancache_conntrack_in':
        desc  => 'Skip incoming connection tracking for mcrouter',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => "proto tcp dport ${port} NOTRACK;",
    }
    if $prometheus_exporter {
        class {'profile::prometheus::mcrouter_exporter':
            mcrouter_port => $mcrouter::port
        }
    }
}
