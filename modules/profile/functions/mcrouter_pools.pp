function profile::mcrouter_pools(String $pool_name, Hash $servers, String $proto, Stdlib::Port $port) >> Hash {
    alert("Vars ${$pool_name} ${servers}");
    {
        $pool_name => {
            'servers' => $servers.map |$shard_slot, $address| {
                    "${address['host']}:${port}:ascii:${proto}"
            }
        }
    }
}
