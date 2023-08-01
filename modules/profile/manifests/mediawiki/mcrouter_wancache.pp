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
    Boolean      $use_onhost_memcached           = lookup('profile::mediawiki::mcrouter_wancache::use_onhost_memcached'),
    Boolean      $use_onhost_memcached_socket    = lookup('profile::mediawiki::mcrouter_wancache::use_onhost_memcached_socket'),
    Boolean      $prometheus_exporter            = lookup('profile::mediawiki::mcrouter_wancache::prometheus_exporter'),
    Hash         $servers_by_datacenter_category = lookup('profile::mediawiki::mcrouter_wancache::shards')
) {

    # install onhost memcached if this server is going to use a Warmup Route
    # MediaWiki servers are running an onhost memcached instance which
    # they query before reaching out to the memcached cluster
    # size should be 1/4 of total memory
    $onhost_port          = 11210

    if $use_onhost_memcached {
        class { '::memcached':
            size               => floor($facts['memorysize_mb'] * 0.25),
            port               => $onhost_port,
            enable_unix_socket => $use_onhost_memcached_socket,
            growth_factor      => 1.25,
            min_slab_size      => 48,
        }
        # NOTE: This should have been a systemd override puppet define but our puppetization
        # of systemd and memcached doesn't really allow for that due to the
        # following problems:
        # * >1 systemd override per service easily isn't supported
        # * memcached class is already using the above said override based on a
        # boolean parameter. It is already differently used on e.g. mc* vs mw* hosts.
        #
        # So, fallback to doing the crappy thing and create the directory
        # on this specific installation and populate the override via a file
        # resources

        # TODO: This should be fixed first at the systemd puppet module level by
        # allowing >1 arbitrary overrides, then memcached class level by
        # untangling the 2 usages above, then this one should become a 2nd
        # systemd override for memcached
        # TODO: uses systemd::override
        file { '/etc/systemd/system/memcached.service.d/':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }
        file { '/etc/systemd/system/memcached.service.d/cpuaccounting-override.conf':
            ensure  => present,
            content => "[Service]\nCPUAccounting=yes\n",
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            notify  => Exec['systemd daemon-reload for memcached.service (memcached)']
        }
        include ::profile::prometheus::memcached_exporter
    }

    $servers_by_datacenter = $servers_by_datacenter_category['wancache']
    $gutters_by_datacenter = $servers_by_datacenter_category['gutter']
    $wikifunctions_servers = $servers_by_datacenter_category['wikifunctions'][$::site]

    if $use_onhost_memcached {
        if $use_onhost_memcached_socket {
            $onhost_pool =  { 'onhost' => {
                                'servers' => [
                                  'unix:/var/run/memcached/memcached.sock:ascii:plain'
                                  ]
                                }
                            }
        } else {
            $onhost_pool = { 'onhost' => {
                                'servers' => [
                                  "127.0.0.1:${onhost_port}:ascii:plain"
                                  ]
                                }
                            }
        }
    } else {
        $onhost_pool = {}
    }

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
    }.reduce($onhost_pool + $gutter_pools + $wikifunction_pool) |$memo, $value| { $memo + $value }

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
        # On-host memcache tier: Keep a short-lived local cache to reduce network load for very hot
        # keys, at the cost of a few seconds' staleness.
        $servers_by_datacenter.map |$dc, $_| {
            $failover_route = $dc ? {
                $::site => true,
                default => false
            };
            {
                'aliases' => [ "/${dc}/mw-with-onhost-tier/" ],
                'route'   => $use_onhost_memcached ? {
                    true  => {
                        'type'               => 'OperationSelectorRoute',
                        'operation_policies' => {
                            # For reads, use WarmUpRoute to try on-host memcache first. If it's not
                            # there, WarmUpRoute tries the ordinary regional pool next, and writes the
                            # result back to the on-host cache, with a short expiration time. The
                            # exptime is ten seconds in order to match our tolerance for DB replication
                            # delay; that level of staleness is acceptable. Based on
                            # https://github.com/facebook/mcrouter/wiki/Two-level-caching#local-instance-with-small-ttl
                            'get' => {
                                'type'    => 'WarmUpRoute',
                                'cold'    => 'PoolRoute|onhost',
                                'warm'    => profile::mcrouter_route($dc, $gutter_ttl, $failover_route),
                                'exptime' => 10,
                            }
                        },
                        # For everything except reads, bypass the on-host tier completely. That means
                        # if a get, set, and get are sent within a ten-second period, they're
                        # guaranteed *not* to have read-your-writes consistency. (If sets updated the
                        # on-host cache, read-your-writes consistency would depend on whether the
                        # requests happened to hit the same host or not, so e.g. mwdebug hosts would
                        # behave differently from the rest of prod, which would be confusing.)
                        'default_policy'     => profile::mcrouter_route($dc, $gutter_ttl, $failover_route)
                    },
                    # If use_onhost_memcached is turned off, always bypass the onhost tier.
                    false => profile::mcrouter_route($dc, $gutter_ttl, $failover_route)
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
