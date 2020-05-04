function profile::mcrouter_route(String $region, Integer $ttl) >> Variant[Hash, String] {
    # For remote sites, the route is always the simple "PoolRoute|${region}"
    if ($region != $::site) {
        "PoolRoute|${region}"
    }
    else {
        {
            'type' => 'FailoverWithExptimeRoute',
            'normal' => "PoolRoute|${region}",
            'failover' => 'PoolRoute|gutter',
            'failover_exptime' => $ttl,
            'failover_errors' => ['tko']

        }
    }
}
