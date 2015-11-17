# These are orphaned sysctls from the webserver::sysctl_settings
# Ancient and mysterious, these can either have absolutely no
# effect on modern kernels or could be the very things that keeps
# the fabric of the space time continuum (and our wikis) alive.
# We do not know, though. So move it here so we can kill the
# webservermodule, and then figure out what to do with these
class base::mysterious_sysctl {
    # Sysctl settings for high-load HTTP caches
    sysctl::parameters { 'high http performance':
        values => {
            # Increase the number of ephemeral ports
            'net.ipv4.ip_local_port_range' =>  [ 1024, 65535 ],

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
