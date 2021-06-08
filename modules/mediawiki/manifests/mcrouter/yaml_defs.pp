# Kubernetes mcrouter pools
# TODO: Add support for plain/TLS and port number
# (requires changes in deployment-charts/charts/mediawiki/templates/mcrouter_config.json.tpl)

class mediawiki::mcrouter::yaml_defs(
    Stdlib::Unixpath $path                 = undef,
    Hash  $servers_by_datacenter_category  = {},
){
    $pools = union(
        $servers_by_datacenter_category['wancache'].map |$datacenter, $servers| {
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
    },
    # TODO: fix when we switch to TLS
    $servers_by_datacenter_category['proxies'].map |$datacenter, $servers| {
        {
            'name' => "${datacenter}-proxies",
            'zone' => $datacenter,
            'servers' =>  $servers.map |$shard_slot, $address| {
                $address['host']
            },
            'failover' =>  $servers.map |$shard_slot, $address| {
                $address['host']
            },
        }
    }
)
    file { $path:
        ensure  => present,
        content => to_yaml({'mw' => {'mcrouter' => $pools}}),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
