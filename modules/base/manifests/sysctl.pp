class base::sysctl {
    # Defaults sysctl parameters for Ubuntu Precise
    # We set them ourselves so we can purge /etc/sysctl.d.
    sysctl::parameters { 'ubuntu precise defaults':
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

            # 10-zeropage.conf
            'vm.mmap_min_addr'                => 65536,

            # We don't want 10-ipv6-privacy.conf, so skip it.
        },
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
        #  FIXME: 50 is our general 'override' priority, so maybe this should be
        #   30 -- more than ubuntu default but less than case-specific overrides?
        priority => '50',
    }
}
