# vim: set sw=4 ts=4 expandtab:

# == Class: role::ipv6relay
#
# Provides Teredo connectivity which let IPv4 only hosts to use IPv6 with us.
class role::ipv6relay {
    system::role { 'role::ipv6relay': description => 'IPv6 tunnel relay (6to4/Teredo)' }

    # Enable router advertisements even when forwarding is enabled
    # ("all" doesn't work with accept_ra, add eth0 here as a hack)
    # Turn on ip forwarding
    sysctl::parameters { 'ipv6 routing':
        values => {
            'net.ipv4.conf.all.forwarding'     => 1,
            'net.ipv4.conf.default.forwarding' => 1,
            'net.ipv6.conf.all.forwarding'     => 1,
            'net.ipv6.conf.default.accept_ra'  => 2,
            'net.ipv6.conf.default.forwarding' => 1,
            'net.ipv6.conf.eth0.accept_ra'     => 2,
        },
    }

    # Teredo
    include miredo

    # 6to4
    interface::tun6to4 { 'tun6to4': }
}
