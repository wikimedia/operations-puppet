class profile::wmcs::google_api_proxy (
    Array[Stdlib::IP::Address] $cache_hosts = lookup('cache_hosts'),
    $instances = lookup('profile::wmcs::google_api_proxy::instances'),
) {
    create_resources(
        '::external_proxy::instance',
        $instances,
        {
            'acls'       => [
                'allow 172.16.0.0/21;  # eqiad1-r private',
                'allow 185.15.56.0/25; # eqiad1-r floating',
                'allow 127.0.0.1;',
                'deny all;',
            ],
            'trusted_xff' => $cache_hosts,
        }
    )
}
