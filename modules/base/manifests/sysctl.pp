class base::sysctl {
    # Ubuntu-inspired default sysctl parameters.
    #
    # These are up-to-date as of *trusty*. These are hand-picked and deemed to
    # be a good idea, so we install them in Debian systems as well.
    #
    # We also set them ourselves so we can purge /etc/sysctl.d.
    sysctl::parameters { 'ubuntu defaults':
        values   => {
            # 10-console-messages.conf
            'kernel.printk'                   => [ 4, 4, 1, 7 ],

            # 10-kernel-hardening.conf
            'kernel.kptr_restrict'            => 1,

            # 10-network-security.conf
            'net.ipv4.conf.default.rp_filter' => 1,
            'net.ipv4.conf.all.rp_filter'     => 1,
            'net.ipv4.tcp_syncookies'         => 1,

            # 10-ptrace.conf
            'kernel.yama.ptrace_scope'        => 1,

            # 10-link-restrictions.conf
            'fs.protected_hardlinks'          => 1,
            'fs.protected_symlinks'           => 1,

            # 10-zeropage.conf
            'vm.mmap_min_addr'                => 65536,

            # skip 10-ipv6-privacy.conf
            # skip 10-magic-sysrq.conf
        },
        priority => 10,
    }

    sysctl::parameters { 'wikimedia base':
        values   => {
            # Increase TCP max buffer size
            'net.core.rmem_max'                => 16777216,
            'net.core.wmem_max'                => 16777216,

            # Increase Linux auto-tuning TCP buffer limits
            # Values represent min, default, & max num. of bytes to use.
            'net.ipv4.tcp_rmem'                => [ 4096, 87380, 16777216 ],
            'net.ipv4.tcp_wmem'                => [ 4096, 65536, 16777216 ],

            # Don't cache ssthresh from previous connection
            'net.ipv4.tcp_no_metrics_save'     => 1,
            'net.core.netdev_max_backlog'      => 2500,

            # Increase the queue size of new TCP connections
            'net.core.somaxconn'               => 1024,
            'net.ipv4.tcp_max_syn_backlog'     => 4096,

            # Swapping makes things too slow and should be done rarely
            # 0 = only swap in OOM conditions (it does NOT disable swap.)
            'vm.swappiness'                    => 0,
            'net.ipv4.tcp_keepalive_time'      => 300,
            'net.ipv4.tcp_keepalive_intvl'     => 1,
            'net.ipv4.tcp_keepalive_probes'    => 2,

            # Default IPv6 route table max_size is too small for the modern
            # Internet.  It's tempting to set this only for public-facing
            # caches and LVS, but when surveying hosts there are non-obvious
            # cases with significant route table sizes (other independent
            # public services with v6, recdns servers, etc..), and even the
            # public ones with smaller live tables would be subject to easier
            # DoS without this setting.  I think it's better to simply set it
            # globally for all our hosts and be done with worrying about it so
            # much.  This value seems to be an order of magnitude+ above what
            # our tier-1 cache nodes currently need, and not cause any issues
            # from being oversized, but this may need adjustment later, unless
            # future kernels fix the issue completely as they did with ipv4.
            'net.ipv6.route.max_size'          => 131072,

            # Mitigate side-channel from challenge acks, at least until most
            # public servers are on kernel 4.7+ or have a backported fix.
            # Refs:
            # CVE-2016-5696
            # http://www.cs.ucr.edu/~zhiyunq/pub/sec16_TCP_pure_offpath.pdf
            # http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=75ff39ccc1bd5d3c455b6822ab09e533c551f758
            'net.ipv4.tcp_challenge_ack_limit' => 987654321,
        },
        priority => 60,
    }

    # unprivileged bpf is a feature introduced in Linux 4.4: https://lwn.net/Articles/660331/
    # We don't need it and it widens the attacks surface for local privilege escalation
    # significantly, so we're disabling it by enabling kernel.unprivileged_bpf_disabled
    if (versioncmp($::kernelversion, '4.4') >= 0) {
        sysctl::parameters { 'disable_unprivileged_bpf':
            values => {
            'kernel.unprivileged_bpf_disabled' => '1',
            },
        }
    }

    # The perf subsystem is a significant attack vector for local privilege escalation vulnerabilities
    # Setting kernel.perf_event_paranoid to 3 disables access to perf for unprivileged users
    # The Debian kernel defaults to that parameter since 4.1.3-1
    if os_version('ubuntu >= precise') {
        sysctl::parameters { 'disable_unprivileged_perf':
            values => {
            'kernel.perf_event_paranoid' => '3',
            },
        }
    }
}
