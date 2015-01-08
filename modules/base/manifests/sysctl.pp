class base::sysctl {
    # Ubuntu-inspired default sysctl parameters.
    #
    # These are up-to-date as of *trusty*. These are hand-picked and deemed to
    # be a good idea, so we install them in Debian systems as well.
    #
    # We also set them ourselves so we can purge /etc/sysctl.d.
    sysctl::parameters { 'ubuntu defaults':
        values => {
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
        values => {
            # Increase TCP max buffer size
            'net.core.rmem_max'             => 16777216,
            'net.core.wmem_max'             => 16777216,

            # Increase Linux auto-tuning TCP buffer limits
            # Values represent min, default, & max num. of bytes to use.
            'net.ipv4.tcp_rmem'             => [ 4096, 87380, 16777216 ],
            'net.ipv4.tcp_wmem'             => [ 4096, 65536, 16777216 ],

            # Don't cache ssthresh from previous connection
            'net.ipv4.tcp_no_metrics_save'  => 1,
            'net.core.netdev_max_backlog'   => 2500,

            # Increase the queue size of new TCP connections
            'net.core.somaxconn'            => 1024,
            'net.ipv4.tcp_max_syn_backlog'  => 4096,

            # Swapping makes things too slow and should be done rarely
            # 0 = only swap in OOM conditions (it does NOT disable swap.)
            'vm.swappiness'                 => 0,
            'net.ipv4.tcp_keepalive_time'   => 300,
            'net.ipv4.tcp_keepalive_intvl'  => 1,
            'net.ipv4.tcp_keepalive_probes' => 2,
        },
        priority => 60,
    }
}
