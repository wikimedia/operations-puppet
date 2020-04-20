function profile::mcrouter_route(String $region, Boolean $use_gutter, Integer $ttl) >> Variant[Hash, String] {
    # For remote sites, or if we're not using the gutter pool,
    # the route is always the simple "PoolRoute|${region}"
    if ($region != $::site or !$use_gutter) {
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
