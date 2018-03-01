# Class profile::dynomite_wancache
#
# Configures a dynomite instance for multi-datacenter caching
class profile::mediawiki::dynomite_wancache(
    $servers_by_datacenter = hiera('mediawiki_wancache_store_servers'),
    $store_port = hiera('mediawiki_wancache_store_port'),
    $port = hiera('mediawiki_wancache_dynomite_port'),
    $stats_port = hiera('mediawiki_wancache_dynomite_stats_port')
) {
    validate_hash($servers_by_datacenter)

    class { '::dynomite':
        pool                     => 'mw-wancache',
        store_type               => 'memcached',
        store_servers            => $servers_by_datacenter,
        store_port               => $store_port,
        region                   => $::site,
        port                     => $port,
        stats_listen             => $stats_port
    }

    class { '::dynomite::monitoring': }

    ferm::rule { 'skip_dynomite_wancache_conntrack_out':
        desc  => 'Skip outgoing connection tracking for dynomite',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => "proto tcp sport (6378:6382 ${port}) NOTRACK;",
    }

    ferm::rule { 'skip_dynomite_wancache_conntrack_in':
        desc  => 'Skip incoming connection tracking for dynomite',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => "proto tcp dport (6378:6382 ${port}) NOTRACK;",
    }
}