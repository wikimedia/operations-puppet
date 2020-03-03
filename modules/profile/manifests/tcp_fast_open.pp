class profile::tcp_fast_open {
    # Enable client/server TCP Fast Open (TFO)
    #
    # The values (bitmap) are:
    # 1: Enables sending data in the opening SYN on the client w/ MSG_FASTOPEN
    # 2: Enables TCP Fast Open on the server side, i.e., allowing data in
    #    a SYN packet to be accepted and passed to the application before the
    #    3-way hand shake finishes
    #
    # Note that, despite the name, this setting is *not* IPv4-specific. TFO
    # support will be enabled on both IPv4 and IPv6
    sysctl::parameters { 'TCP Fast Open':
        values => {
            'net.ipv4.tcp_fastopen' => 3,
        },
    }
}
