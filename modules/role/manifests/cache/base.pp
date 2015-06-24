class role::cache::base(
    $cluster_tier = 'two',
    $purge_host_only_upload_re = '/./',
    $purge_host_not_upload_re = '/./'
) {
    include standard
    include nrpe
    include lvs::configuration
    include role::cache::configuration
    include role::cache::statsd
    include network::constants

    # Only production needs these system perf tweaks
    if $::realm == 'production' {
        include role::cache::perf
    }

    $wikimedia_networks = flatten([$network::constants::all_networks, '127.0.0.0/8', '::1/128'])
}
