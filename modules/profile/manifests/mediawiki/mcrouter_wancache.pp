# Class profile::mcrouter_wancache
#
# Configures a mcrouter instance for multi-datacenter caching
class profile::mediawiki::mcrouter_wancache(
    Hash $servers_by_datacenter_category = hiera('mcrouter::shards'),
    Integer $port = hiera('mcrouter::port'),
    Boolean $has_ssl = hiera('mcrouter::has_ssl'),
    Integer $ssl_port = hiera('mcrouter::ssl_port', $port + 1),
    Integer $num_proxies = hiera('profile::mediawiki::mcrouter_wancache::num_proxies', 1),
    Optional[Integer] $timeouts_until_tko = lookup('profile::mediawiki::mcrouter_wancache::timeouts_until_tko', {'default_value' => 10}),
    Integer $gutter_ttl = lookup('profile::mediawiki::mcrouter_wancache::gutter_ttl', {'default_value' => 60}),
) {

    $servers_by_datacenter = $servers_by_datacenter_category['wancache']
    $proxies_by_datacenter = pick($servers_by_datacenter_category['proxies'], {})
    # We only need to configure the gutter pool for DC-local routes. Remote-DC
    # routes are reached via an mcrouter proxy in that dc, that will be
    # configured to use its gutter pool itself.
    $local_gutter_pool = profile::mcrouter_pools('gutter', $servers_by_datacenter_category['gutter'][$::site])

    $pools = $servers_by_datacenter.map |$region, $servers| {
        # We need to get the servers from the current datacenter, and the proxies from the others
        if $region == $::site {
            profile::mcrouter_pools($region, $servers)
        } else {
            profile::mcrouter_pools($region, $proxies_by_datacenter[$region])
        }
    }
    .reduce($local_gutter_pool) |$memo, $value| { $memo + $value }

    $routes = union(
        # local cache for each region
        $servers_by_datacenter.map |$region, $servers| {
            {
                'aliases' => [ "/${region}/mw/" ],
                'route' => profile::mcrouter_route($region, $gutter_ttl)  # @TODO: force $::site like mw-wan default?
            }
        },
        # WAN cache: issues reads and add/cas/touch locally and issues set/delete everywhere.
        # MediaWiki will set a prefix of /*/mw-wan when broadcasting, explicitly matching
        # all the mw-wan routes. Broadcasting is thus completely controlled by MediaWiki,
        # but is only allowed for set/delete operations.
        $servers_by_datacenter.map |$region, $servers| {
            {
                'aliases' => [ "/${region}/mw-wan/" ],
                'route'   => {
                    'type'               => 'OperationSelectorRoute',
                    'default_policy'     => profile::mcrouter_route($::site, $gutter_ttl), # We want reads to always be local!
                    # AllAsyncRoute is used by mcrouter when replicating data to the non-active DC:
                    # https://github.com/facebook/mcrouter/wiki/List-of-Route-Handles#allasyncroute
                    # More info in T225642
                    'operation_policies' => {
                        'set'    => {
                            'type'     => $region ? {
                                $::site => 'AllSyncRoute',
                                default => 'AllAsyncRoute'
                            },
                            'children' => [ profile::mcrouter_route($region, $gutter_ttl) ]
                        },
                        'delete' => {
                            'type'     => $region ? {
                                $::site => 'AllSyncRoute',
                                default => 'AllAsyncRoute'
                            },
                            'children' => [ profile::mcrouter_route($region, $gutter_ttl) ]
                        },
                    }
                }
            }
        }
    )
    if $has_ssl {
        file { '/etc/mcrouter/ssl':
            ensure  => directory,
            owner   => 'mcrouter',
            group   => 'root',
            mode    => '0750',
            require => Package['mcrouter'],
        }
        file { '/etc/mcrouter/ssl/ca.pem':
            ensure  => present,
            content => secret('mcrouter/mcrouter_ca/ca.crt.pem'),
            owner   => 'mcrouter',
            group   => 'root',
            mode    => '0444',
        }

        file { '/etc/mcrouter/ssl/cert.pem':
            ensure  => present,
            content => secret("mcrouter/${::fqdn}/${::fqdn}.crt.pem"),
            owner   => 'mcrouter',
            group   => 'root',
            mode    => '0444',
        }

        file { '/etc/mcrouter/ssl/key.pem':
            ensure  => present,
            content => secret("mcrouter/${::fqdn}/${::fqdn}.key.private.pem"),
            owner   => 'mcrouter',
            group   => 'root',
            mode    => '0400',
        }

        $ssl_options = {
            'port'    => $ssl_port,
            'ca_cert' => '/etc/mcrouter/ssl/ca.pem',
            'cert'    => '/etc/mcrouter/ssl/cert.pem',
            'key'     => '/etc/mcrouter/ssl/key.pem',
        }

        # We can allow any other mcrouter to connect via SSL here
        ferm::service { 'mcrouter_ssl':
            desc    => 'Allow connections to mcrouter via SSL',
            proto   => 'tcp',
            notrack => true,
            port    => $ssl_port,
            srange  => '$DOMAIN_NETWORKS',
        }
    }
    else {
        $ssl_options = undef
    }

    class { '::mcrouter':
        pools              => $pools,
        routes             => $routes,
        region             => $::site,
        cluster            => 'mw',
        num_proxies        => $num_proxies,
        timeouts_until_tko => $timeouts_until_tko,
        port               => $port,
        ssl_options        => $ssl_options,
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
