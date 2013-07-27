# vim: set sw=4 ts=4 expandtab:

# == Class: role::ipv6relay
#
# Provides Teredo connectivity which let IPv4 only hosts to use IPv6 with us.
class role::ipv6relay {
    system_role { 'role::ipv6relay': description => 'IPv6 tunnel relay (6to4/Teredo)' }

    include sysctlfile::advanced-routing-ipv6

    # Teredo
    include misc::miredo

    # 6to4
    interface_tun6to4 { 'tun6to4': }
}
