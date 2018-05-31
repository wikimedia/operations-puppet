# Class profile::mcrouter_wancache
#
# Configures a mcrouter instance for multi-datacenter caching
# TODO: use a non-root user
class profile::mediawiki::mcrouter_wancache(
    Hash $servers_by_datacenter_category = hiera('mcrouter::shards'),
    Integer $port = hiera('mcrouter::port'),
    Boolean $has_ssl = hiera('mcrouter::has_ssl'),
    Integer $ssl_port = hiera('mcrouter::ssl_port', $port + 1),
) {
    $servers_by_datacenter = $servers_by_datacenter_category['wancache']
    $proxies_by_datacenter = pick($servers_by_datacenter_category['proxies'], {})

    $pool_configs = $servers_by_datacenter.map |$region, $servers| {
        # We need to get the servers from the current datacenter, and the proxies from the others
        if $region == $::site {
            profile::mcrouter_pools($region, $servers)
        } else {
            profile::mcrouter_pools($region, $proxies_by_datacenter[$region])
        }
    }
    $pools = $pool_configs.reduce |$memo, $value| {
        $memo + $value
    }

    $routes = union(
        # local cache for each region
        $servers_by_datacenter.map |$region, $servers| {
            {
                'aliases' => [ "/${region}/mw/" ],
                'route'   => "PoolRoute|${region}"
            }
        },
        # WAN cache: read locally, set/delete everywhere.
        # MediaWiki will set a prefix of /*/mw-wan when broadcasting, explicitly matching
        # all the mw-wan routes. Broadcasting is thus completely controlled by MediaWiki,
        # but is only allowed for set/delete operations
        $servers_by_datacenter.map |$region, $servers| {
            {
                'aliases' => [ "/${region}/mw-wan/" ],
                'route'   => {
                    'type'           => 'OperationSelectorRoute',
                    'default_policy' => "PoolRoute|${::site}", # We want reads to always be local!
                    'operation_policies' => {
                        'set'    => "PoolRoute|${region}",
                        'delete' => "PoolRoute|${region}",
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
            source => secret('mcrouter/mcrouter_ca/ca.crt.pem')
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        file { '/etc/mcrouter/ssl/cert.pem':
            ensure  => present,
            content => secret("mcrouter/${::fqdn}/${::fqdn}.crt.pem"),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
        }

        file { '/etc/mcrouter/ssl/key.pem':
            ensure  => present,
            content => secret("mcrouter/${::fqdn}/${::fqdn}.key.private.pem"),
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
        }

        $ssl_options = {
            'port'    => $ssl_port,
            'ca_cert' => '/etc/mcrouter/ssl/ca.pem',
            'cert'    => '/etc/mcrouter/ssl/cert.pem',
            'key'     => '/etc/mcrouter/ssl/key.pem',
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
        rule  => "proto tcp sport (${port} ${ssl_port}) NOTRACK;",
    }

    ferm::rule { 'skip_mcrouter_wancache_conntrack_in':
        desc  => 'Skip incoming connection tracking for mcrouter',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => "proto tcp dport (${port} ${ssl_port}) NOTRACK;",
    }
}
