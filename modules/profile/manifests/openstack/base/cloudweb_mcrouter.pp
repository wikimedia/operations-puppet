# Class profile::openstack::base::cloudweb_mcrouter
#
# Configures a mcrouter cluster which pools all cloudweb hosts
#
class profile::openstack::base::cloudweb_mcrouter(
    Array[Stdlib::Fqdn] $cloudweb_hosts = lookup('profile::openstack::base::labweb_hosts'),
    Stdlib::Port        $mcrouter_port  = lookup('profile::openstack::base::cloudweb::mcrouter_port'),
    Integer             $memcached_size = lookup('profile::openstack::base::cloudweb_memcached_size'),
    String[1]           $memcached_user = lookup('profile::openstack::base::cloudweb::memcached_user'),
) {
    # Replicated cache set including all cloudweb hosts.
    #
    # This is used for Horizon session and page caching.  Note
    #  that it's easy to start losing sessions if the cache size
    #  is too small (T145703)
    #
    # The route config here is copy/pasted from
    #  https://github.com/facebook/mcrouter/wiki/Replicated-pools-setup
    #
    # The cross-region bits don't actually matter but the parent class expects them.
    class { '::mcrouter':
        region                   => $::site,
        cluster                  => 'cloudweb',
        cross_region_timeout_ms  => 250,
        cross_cluster_timeout_ms => 1000,
        pools                    => {
            'cloudweb' => {
                servers => $cloudweb_hosts.map |$cloudwebhost| { sprintf('%s:11000:ascii:plain',ipresolve($cloudwebhost,4)) }
            },
        },
        routes                   => [
            aliases              => [ "/${::site}/cloudweb/" ],
            route                => {
                type               => 'OperationSelectorRoute',
                default_policy     => 'PoolRoute|cloudweb',
                operation_policies => {
                    add    => 'AllFastestRoute|Pool|cloudweb',
                    delete => 'AllFastestRoute|Pool|cloudweb',
                    get    => 'LatestRoute|Pool|cloudweb',
                    set    => 'AllFastestRoute|Pool|cloudweb'
                }
            }
        ]
    }

    class { '::memcached':
        size           => $memcached_size,
        # TODO: the following were implicit defaults from
        # MW settings, need to be reviewed.
        growth_factor  => 1.05,
        min_slab_size  => 5,
        memcached_user => $memcached_user,
    }
    class { '::profile::prometheus::memcached_exporter': }

    ferm::rule { 'skip_mcrouter_cloudweb_conntrack_out':
        desc  => 'Skip outgoing connection tracking for mcrouter',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => "proto tcp sport (${mcrouter_port}) NOTRACK;",
    }

    ferm::rule { 'skip_mcrouter_cloudweb_conntrack_in':
        desc  => 'Skip incoming connection tracking for mcrouter',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => "proto tcp dport (${mcrouter_port}) NOTRACK;",
    }

    ferm::service { 'mcrouter':
        desc    => 'Allow connections to mcrouter',
        proto   => 'tcp',
        notrack => true,
        port    => $mcrouter_port,
        srange  => "(@resolve((${join($cloudweb_hosts,' ')}))
                    @resolve((${join($cloudweb_hosts,' ')}), AAAA))",
    }

    ferm::service { 'memcached_for_mcrouter':
        desc    => 'Allow connections to memcached',
        proto   => 'tcp',
        notrack => true,
        port    => 11000,
        srange  => "(@resolve((${join($cloudweb_hosts,' ')}))
                    @resolve((${join($cloudweb_hosts,' ')}), AAAA))",
    }
}
