class role::cache::base(
    $cluster_tier = 'two',
    $default_backend = $::mw_primary,
    $purge_host_only_upload_re = '/./',
    $purge_host_not_upload_re = '/./'
) {
    include lvs::configuration
    include role::cache::configuration
    include network::constants

    # Only production needs these system perf tweaks
    if $::realm == 'production' {
        include role::cache::perf
    }

    $wikimedia_networks = flatten([$network::constants::all_networks, '127.0.0.0/8', '::1/128'])
}
