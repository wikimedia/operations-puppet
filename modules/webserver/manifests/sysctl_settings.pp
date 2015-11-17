class webserver::sysctl_settings {
    # Sysctl settings for high-load HTTP caches
    sysctl::parameters { 'high http performance':
        values => {
            # Recommended to increase this for 1000 BT or higher
            'net.core.netdev_max_backlog'  =>  30000,

            # Increase the queue size of new TCP connections
            'net.core.somaxconn'           => 4096,
            'net.ipv4.tcp_max_syn_backlog' => 262144,
            'net.ipv4.tcp_max_tw_buckets'  => 360000,

            # Decrease FD usage
            'net.ipv4.tcp_fin_timeout'     => 3,
            'net.ipv4.tcp_max_orphans'     => 262144,
            'net.ipv4.tcp_synack_retries'  => 2,
            'net.ipv4.tcp_syn_retries'     => 2,
        },
    }

}
