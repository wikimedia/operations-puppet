function profile::mcrouter_pools(String $region, Hash $servers) >> Hash {
    $servers.map |$shard, $server| {
        {
            $region => {
                'servers' => $servers.map |$shard_slot, $address| {
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
}
