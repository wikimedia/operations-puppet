# This class contains production-specific performance hacks
# These should have zero functional effect, they are merely system-level
# tweaks to support heavy load/traffic.
class role::cache::perf {
    include cpufrequtils # defaults to "performance"

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
