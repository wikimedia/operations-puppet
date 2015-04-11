# Ancestor class for all Varnish clusters
class role::cache::base {
    include lvs::configuration
    include role::cache::configuration
    include network::constants

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

    # This seems to prevent long term memory fragmentation issues that
    #  can cause VM perf issues.  This seems to be less necessary on jessie
    #  with other assorted fixes in place, and we could experiment with
    #  removing it entirely at a later time when things are more stable.
    #  (watch for small but increasing sys% spikes on upload caches if so,
    #  may take days to have real effect).
    cron { 'varnish_vm_compact_cron':
        command => 'echo 1 >/proc/sys/vm/compact_memory',
        user    => 'root',
        minute  => '*',
    }

    #class { "varnish::packages": version => "3.0.3plus~rc1-wm5" }

    # Prod-specific performance tweaks
    if $::realm == 'production' {
        include cpufrequtils # defaults to "performance"

        # Bump min_free_kbytes to ensure network buffers are available quickly
        #   without having to evict cache on the spot
        vm::min_free_kbytes { 'cache':
            pct => 2,
            min => 131072,
            max => 1048576,
        }

        # RPS/RSS to spread network i/o evenly
        interface::rps { 'eth0': }

        # flush vm more steadily in the background. helps avoid large performance
        #   spikes related to flushing out disk write cache.
        sysctl::parameters { 'cache_role_vm_settings':
            values => {
                'vm.dirty_ratio'            => 40,  # default 20
                'vm.dirty_background_ratio' => 5,   # default 10
                'vm.dirty_expire_centisecs' => 500, # default 3000
            },
        }

        # Disable TCP SSR (slow-start restart). SSR resets the congestion
        # window of connections that have gone idle, which means it has a
        # tendency to reset the congestion window of HTTP keepalive and SPDY
        # connections, which are characterized by short bursts of activity
        # separated by long idle times.
        sysctl::parameters { 'disable_ssr':
            values => { 'net.ipv4.tcp_slow_start_after_idle' => 0 },
        }
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
