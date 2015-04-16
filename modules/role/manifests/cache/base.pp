class role::cache::base {
    include lvs::configuration
    include role::cache::configuration
    include network::constants

    # Only production needs these system perf tweaks
    if $::realm == 'production' {
        include role::cache::perf
    }

    # Any changes here will affect all descendent Varnish clusters
    # unless they're overridden!
    if $::site in ['eqiad'] {
        $cluster_tier = 1
        $default_backend = 'backend'
    } else {
        $cluster_tier = 2
        $default_backend = $::mw_primary
    }
    $wikimedia_networks = flatten([$network::constants::all_networks, '127.0.0.0/8', '::1/128'])

    # These regexes are for optimization of PURGE traffic by having
    #   non-upload sites ignore upload purges and having upload
    #   ignore everything but upload purges via purge_host_regex
    #   in child classes where warranted.
    $purge_host_only_upload_re = $::realm ? {
        'production' => '^upload\.wikimedia\.org$',
        'labs'       => '^upload\.beta\.wmflabs\.org$',
    }
    $purge_host_not_upload_re = $::realm ? {
        'production' => '^(?!upload\.wikimedia\.org)',
        'labs' => '^(?!upload\.beta\.wmflabs\.org)',
    }
}
