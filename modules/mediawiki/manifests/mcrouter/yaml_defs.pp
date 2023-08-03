# Kubernetes mcrouter pools
# TODO: Add support for plain/TLS and port number
# (requires changes in deployment-charts/charts/mediawiki/templates/mcrouter_config.json.tpl)

class mediawiki::mcrouter::yaml_defs(
    Stdlib::Unixpath $path                 = undef,
    Stdlib::Port $memcached_notls_port     = undef,
    Stdlib::Port $memcached_tls_port       = undef,
    Hash  $servers_by_datacenter_category  = {},
){
    $wancache_pools = $servers_by_datacenter_category['wancache'].map |$datacenter, $servers| {
        {
            'name' => "${datacenter}-servers",
            'zone' => $datacenter,
            'servers' =>  $servers.map |$shard_slot, $address| {
                $address['host']
              },
            'failover' => $servers_by_datacenter_category['gutter'][$datacenter].map |$shard_slot, $address| {
                $address['host']
            },
        }
    }
    $wikifunctions_pool = $servers_by_datacenter_category['wikifunctions'].map |$dc, $servers| {
        {
            'name' => "wf-${dc}",
            'zone' => $dc,
            'servers' =>  $servers.map |$shard_slot, $address| {
                $address['host']
            },
        }
    }

    file { $path:
        ensure  => present,
        content => to_yaml(
            {'cache' => {'mcrouter' => {
                'pools'                => $wancache_pools + $wikifunctions_pool,
                'memcached_notls_port' => $memcached_notls_port,
                'memcached_tls_port'   => $memcached_tls_port
            }}}
        ),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
