class base::sysctl {
    # Systemctl hardening settings. We set them ourselves so we can purge /etc/sysctl.d.
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

    # BBR congestion control (T147569)
    # https://lwn.net/Articles/701165/
    #
    # The BBR TCP congestion control algorithm is based on Bottleneck
    # Bandwidth, i.e. the estimated bandwidth of the slowest link, and
    # Round-Trip Time to control outgoing traffic. Other algorithms such as
    # CUBIC (default on Linux since 2.6.19) and Reno are instead based on
    # packet loss.
    #
    # To send out data at the proper rate, BBR uses the tc-fq packet scheduler
    # instead of the TCP congestion window.
    #
    # It has been added to Linux in version 4.9.
    $use_bbr = hiera('bbr_congestion_control', false)
    if ($use_bbr) and (versioncmp($::kernelversion, '4.9') >= 0) {
        sysctl::parameters { 'tcp_bbr':
            values => {
                'net.core.default_qdisc'          => 'fq',
                'net.ipv4.tcp_congestion_control' => 'bbr',
            },
        }
    }
    # The security fix for CVE-2019-11479 introduced a new sysctl setting which clamps
    # the lower value for the advertised MSS. The Linux patch retains the formerly
    # hardcoded default of 48 for backwards compatibility reasons. We're setting it to
    # 538 which is the minimum MTU for IPv4 minus the size of the headers, which should
    # allow all legitimate traffic while avoiding the resource exhaustion.
    #
    # All the kernels which have CVE-2019-11479 backported, also have the fixes for
    # CVE-2019-11477 and CVE-2019-11478 applied. Re-enable TCP selective acknowledments
    # on all hosts which have been rebooted to that kernel and keep it disabled for all
    # servers still running an unfixed kernel.
    if $facts.has_key('kernel_details') and
        $facts['kernel_details']['sysctl_settings']['net.ipv4.tcp_min_snd_mss'] {
        sysctl::parameters{'tcp_min_snd_mss':
            values  => {
                'net.ipv4.tcp_min_snd_mss' => '538',
                'net.ipv4.tcp_sack'        => 1,
            },
        }
    } else {
        sysctl::parameters{'disable_tcp_sack':
            values  => { 'net.ipv4.tcp_sack' => 0 },
        }
    }
}
