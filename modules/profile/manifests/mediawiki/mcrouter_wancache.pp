# Class profile::mcrouter_wancache
#
# Configures a mcrouter instance for multi-datacenter caching
# TODO: fix notrack defs
# TODO: use a non-root user
class profile::mediawiki::mcrouter_wancache(
    Hash $servers_by_datacenter_category = hiera('mcrouter::shards'),
    Integer $port = hiera('profile::mediawiki::mcrouter_wancache::port'),
    Boolean $has_ssl = hiera('profile::mediawiki::mcrouter_wancache::has_ssl')
) {
    $servers_by_datacenter = $servers_by_datacenter_category['wancache']
    $proxies_by_datacenter = pick($servers_by_datacenter_category['proxies'], {})

    $pool_configs = $servers_by_datacenter.map |$region, $servers| {
        # We need to get the servers from the current datacenter, and the proxies from the others
        $servers_ = $region ? {
            $::site => $servers,
            default => $proxies_by_datacenter[$region]
        }
        {
            $region => {
                'servers' => $servers_.map |$shard_slot, $address| {
                    if $address['ssl'] == true {
                        "${address['host']}:${address['port']}:ascii:ssl"
                    }
                    else {
                        "${address['host']}:${address['port']}:ascii:plain"
                    }
                }
            }
        }
    }
    $pools = $pool_configs.reduce |$memo, $value| {
        $memo + $value
    }

    $route_config_all_regions = {
        'type'     => 'AllFastestRoute',
        'children' => keys($servers_by_datacenter).map |$region| { "PoolRoute|${region}" }
    }

    $routes = union(
        # local cache for each region
        $servers_by_datacenter.map |$region, $servers| {
            {
                'aliases' => [ "/${region}/mw/" ],
                'route'   => "PoolRoute|${region}"
            }
        },
        # WAN cache: read locally, set/delete everywhere
        $servers_by_datacenter.map |$region, $servers| {
            {
                'aliases' => [ "/${region}/mw-wan/" ],
                'route'   => {
                    'type'           => 'OperationSelectorRoute',
                    'default_policy' => "PoolRoute|${region}",
                    'operation_policies' => {
                        'set'    => $route_config_all_regions,
                        'delete' => $route_config_all_regions,
                    }
                }
            }
        }
    )
    if $has_ssl {
        file { '/etc/mcrouter/ssl':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0750',
        }
        file { '/etc/mcrouter/ssl/ca.pem':
            ensure => present,
            source => 'puppet:///modules/profile/mcrouter/ssl/ca.pem',
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        file { '/etc/mcrouter/ssl/cert.pem':
            ensure => present,
            source => secret("mcrouter/ssl/${::ipaddress}.cert.pem"),
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        file { '/etc/mcrouter/ssl/key.pem':
            ensure => present,
            source => secret("mcrouter/ssl/${::ipaddress}.key.pem"),
            owner  => 'root',
            group  => 'root',
            mode   => '0400',
        }

        $ssl_options = {
            'port' => ($port + 1),
            'ca_cert' => '/etc/mcrouter/ssl/ca.pem',
            'cert' => '/etc/mcrouter/ssl/cert.pem',
            'key' => '/etc/mcrouter/ssl/key.pem',
        }
    }
    else {
        $ssl_options = undef
    }

    class { '::mcrouter':
        pools                    => $pools,
        routes                   => $routes,
        region                   => $::site,
        cluster                  => 'mw',
        cross_region_timeout_ms  => 250,
        cross_cluster_timeout_ms => 1000,
        port                     => $port,
        ssl_options              => $ssl_options,
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
