class profile::wmcs::google_api_proxy (
    Array[Stdlib::IP::Address] $cache_hosts = lookup('cache_hosts'),
    $instances = lookup('profile::wmcs::google_api_proxy::instances'),
) {
    include network::constants
    $allowed_networks = $network::constants::all_cloud_instance_networks + $network::constants::all_cloud_floating_networks + ['127.0.0.1', '::1']
    $network_acls = $allowed_networks.map |Stdlib::IP::Address $cidr| { "allow ${cidr};" }

    create_resources(
        '::external_proxy::instance',
        $instances,
        {
            'acls'        => $network_acls + [ 'deny all;' ],
            'trusted_xff' => $cache_hosts,
        }
    )
}
