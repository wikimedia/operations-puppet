# Kubernetes redis pools
# Each pool has a listening port, but currently nutcracker listens to unix sockers
# while in kubernetes each pool will be listening to a TCP port. There is no
# harm to temporarily statically define the kubernetes TCP port for each pool here

class mediawiki::nutcracker::yaml_defs(
    Stdlib::Unixpath $path = undef,
    Hash $redis_shards    = {},
    Hash $nutcracker_ports = { 'eqiad' => 12000, 'codfw' => 12001},

){
    $pools = $redis_shards['sessions'].map |$datacenter, $servers| {
        {
            'name' => $datacenter,
            'port' => $nutcracker_ports[$datacenter],
            'servers' =>  $servers.map |$shard_slot, $hostinfo| {
                {
                    'shard' => $shard_slot,
                    'host'  => $hostinfo['host'],
                    'port'  => $hostinfo['port']
                }
                },
        }
    }
    file { $path:
        ensure  => present,
        content => to_yaml({'mw' => {'nutcracker' => {'pools' => $pools}}}),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
