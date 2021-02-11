function profile::mcrouter_pools(String $region, Hash $servers) >> Hash {
    {
        $region => {
            'servers' => $servers.map |$shard_slot, $address| {
                if $address['socket'] {
                    "unix:${$address['socket']}:ascii:plain"
                } elsif  $address['ssl'] == true {
                    "${address['host']}:${address['port']}:ascii:ssl"
                } else {
                    "${address['host']}:${address['port']}:ascii:plain"
                }
            }
        }
    }
}
