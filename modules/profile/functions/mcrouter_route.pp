function profile::mcrouter_route(String $dc, Integer $ttl, Boolean $failover_route) >> Variant[Hash, String] {
    # For remote sites, the route is always the simple "PoolRoute|${region}"
    if  $failover_route {
        {
            'type' => 'FailoverWithExptimeRoute',
            'normal' => "PoolRoute|${dc}",
            'failover' => "PoolRoute|${dc}-gutter",
            'failover_exptime' => $ttl,
            'failover_errors' => ['tko']

        }
    } else  {
        "PoolRoute|${dc}"
    }
}
