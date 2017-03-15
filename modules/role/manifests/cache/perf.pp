# This class contains production-specific performance hacks
# These should have zero functional effect, they are merely system-level
# tweaks to support heavy load/traffic.
class role::cache::perf {
    include cpufrequtils # defaults to "performance"

    # Bump min_free_kbytes to ensure network buffers are available quickly
    #   without having to evict cache on the spot
    vm::min_free_kbytes { 'cache':
        pct => 2,
        min => 131072,
        max => 2097152,
    }

    grub::bootparam { 'tcpmhash_entries':
        value => 65536,
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

    # Network tuning for high-load HTTP caches
    sysctl::parameters { 'cache proxy network tuning':
        values => {
            # Increase the number of ephemeral ports
            'net.ipv4.ip_local_port_range'       => [ 4001, 65534 ],

            # All prod caches are 10GbE, standard recommendation is 300K for 10G
            # and 30K for 1G.  Our inbound traffic max is closer to 1G levels,
            # since we have 10G LVS splitting traffic to ~8 or more hosts for
            # high-traffic clusters.  Still, we should double the 1GbE numbers
            # at least, just in case of bursts and inequality, etc.  If low,
            # will see drops in col 2 of /proc/net/softnet_stat
            'net.core.netdev_max_backlog'        => 60000,

            # budget: Similar to the above, default 300, and is the #packets
            # handled per NAPI polling cycle across all interfaces.  You can see
            # effects of this being too low in col 3 of /proc/net/softnet_stat.
            # Caches show some small numbers there, so, experimenting with
            # raising this a bit for now
            'net.core.netdev_budget'             => 1024,

            # Default:1 - setting this to zero defers timestamping until after
            # RPS.  It's more efficient this way, but timestamp doesn't account
            # for any tiny delays in queueing before RPS, which I don't think is
            # an issue in our case.
            'net.core.netdev_tstamp_prequeue'    => 0,

            # Our rate of incoming SYN on heaviest cp hosts peaks around
            # 1-2K/sec.  For somaxconn, the SYN numbers should be multiplied
            # out for a few seconds of headroom (bursts, and userspace delays)
            # and then perhaps doubled again to handle the influx of depooling
            # large datacenters.  Note somaxconn is just a parameter limit, the
            # application still needs to set this explicitly (within the
            # limit).
            'net.core.somaxconn'                 => 16384,

            # Our active connection concurrency peaks in the ~100K-200K range
            # per cp host (e.g. text esams as shown in ipvsadm).  For
            # max_syn_backlog, we probably want a small multiple of peak
            # concurrency (maybe even just ~1x), as well as (again) dc failover
            # and/or cp host depool headroom.
            'net.ipv4.tcp_max_syn_backlog'       => 524288,

            # Building on the metrics above - tw_buckets should be somewhere
            # close to the concurrency/syn_backlog sort of level as well so that
            # we properly timewait connections when necc.  Note that tw_reuse
            # moderates the localhost<->localhost timewaits.  max_orphans should
            # be close to the same value, I think, as most of the lingering TW
            # will be orphans.
            'net.ipv4.tcp_max_tw_buckets'        => 524288,
            'net.ipv4.tcp_max_orphans'           => 524288,

            # tcp_tw_(reuse|recycle): both are off by default
            # http://vincent.bernat.im/en/blog/2014-tcp-time-wait-state-linux.html
            #    _recycle is dangerous: it violates RFCs, and probably breaks
            # clients when many clients are behind a single NAT gateway, and
            # affects the recycling of TIME_WAIT slots for both incoming and
            # outgoing connections.
            #    _reuse is not-so-dangerous: it only affects outgoing
            # connections, and looks at timestamp and other state information to
            # gaurantee that the reuse doesn't cause issues within reasonable
            # constraints.
            #    This helps prevent TIME_WAIT issues for our $localip<->$localip
            # connections from nginx to varnish-fe:80 - some of our caches reach
            # connection volume/rate spikes where this is a real issue.
            'net.ipv4.tcp_tw_reuse'              => 1,

            # FIN_WAIT_2 orphan time, def 60.  Reducing this reduces wasted
            # sockets and memory, and there's no good reason to set it higher
            # than roughly the maximum reasonable client RTT in our case.
            'net.ipv4.tcp_fin_timeout'           => 3,

            # Defaults are synack:5 and syn:6.  These control retries on SYN
            # (outbound) and SYNACK (inbound) before giving up on connection
            # establishment.  The defaults with the normal backoff timers can
            # leave not-yet-connected sockets lingering for unacceptably-long
            # times (1-2 minutes).  Aside from waste, that's also a potential
            # DoS vector we'd rather not have.  The "2" value drops the maximum
            # time windows down to ~7 seconds.
            'net.ipv4.tcp_synack_retries'        => 2,
            'net.ipv4.tcp_syn_retries'           => 2,

            # tcp_slow_start_after_idle: SSR resets the congestion window of
            # connections that have gone idle, which means it has a tendency to
            # reset the congestion window of HTTP keepalive and HTTP/2
            # connections, which are characterized by short bursts of activity
            # separated by long idle times.
            'net.ipv4.tcp_slow_start_after_idle' => 0,

            # tcp_notsent_lowat: Default is -1 (unset).  The default behavior is
            # to keep the socket writeable until the whole socket buffer fills.
            # With this set, even if there's buffer space, the kernel doesn't
            # notify of writeability (e.g. via epoll()) until the amount of
            # unsent data (as opposed to unacked) in the socket buffer is less
            # than this value.  This reduces local buffer bloat on our server's
            # sending side, which may help with HTTP/2 prioritization.  The
            # magic value for tuning is debateable, but arguably even setting a
            # conservative (higher) value here is better than not setting it
            # all, in almost all cases for any kind of TCP traffic.  ~128K seems
            # to be a common recommendation for something close-ish to optimal
            # for internet-facing things.
            'net.ipv4.tcp_notsent_lowat'         => 131072,

            # EXPERIMENTAL!
            # TCP autocorking exists and defaults on from 3.14 onwards.  The
            # idea is that some applications that should be doing a better job
            # of local buffering or manual TCP_CORK aren't, and the kernel
            # detects the common patterns for this and auto-corks for them
            # (doesn't immediately send a small write, instead waits a bit to
            # see if it can coalesce it with another).  Netstat counters for
            # autocorking are running up at a huge rate (ballpark near our reqs
            # or SYNs rate), which implies this is happening commonly to nginx
            # outbound traffic.  My theory is this is probably a net loss and
            # nginx and/or openssl know what they're doing and we'd benefit from
            # the writes going out immediately and not autocorking...
            'net.ipv4.tcp_autocorking'           => 0,

            # EXPERIMENTAL!
            # no_metrics_save: default 0.  Most tuning advice on the internet
            # says set it to 1, our own base-level sysctls for all systems also
            # set it to 1.  I think it's possible this advice is outdated and
            # harmful.  The rationale for no_metrics_save is that if there's
            # congestion/loss, congestion algorithms will cut down the cwnd of
            # the active connection very aggressively, and are very slow at
            # recovering from even small bursts of loss, and metrics cache will
            # carry this over to new connections after a temporary loss burst
            # that's already ended.  However, Linux 3.2+ implements PRR (RFC
            # 6937), which mitigates these issues and allows faster/fuller
            # recovery from loss bursts.  That should reduce the downsides of
            # saving metrics significantly, and the upsides have always been a
            # win because we remember (for an hour) past RTT, ssthresh, cwnd,
            # etc, which often allow better initial connection conditions.
            # Kernel boot param 'tcpmhash_entries' sets hash table slots for
            # this.
            'net.ipv4.tcp_no_metrics_save'       => 0,
        },
    }
}
