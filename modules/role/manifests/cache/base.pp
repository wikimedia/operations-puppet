# Ancestor class for all Varnish clusters
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

    $storage_partitions = $::realm ? {
        'production' => ['sda3', 'sdb3'],
        'labs'       => ['vdb'],
    }

    # mma: mmap addrseses for fixed persistent storage on x86_64 Linux:
    #  This scheme fits 4x fixed memory mappings of up to 4TB each
    #  into the range 0x500000000000 - 0x5FFFFFFFFFFF, which on
    #  x86_64 Linux is in the middle of the user address space and thus
    #  unlikely to ever be used by normal, auto-addressed allocations,
    #  as those grow in from the edges (typically from the top, but
    #  possibly from the bottom depending).  Regardless of which
    #  direction heap grows from, there's 32TB or more for normal
    #  allocations to chew through before they reach our fixed range.
    $mma0 = 0x500000000000
    $mma1 = 0x540000000000
    $mma2 = 0x580000000000
    $mma3 = 0x5C0000000000

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
