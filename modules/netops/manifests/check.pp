# == Define: netops::check
#
# Sets up various monitoring checks for a given networking device.
#
# === Parameters
#
# [*ipv4*]
#   The IPv4 address of the device. Required.
#
# [*ipv6*]
#   The IPv6 address of the device. Optional.
#
# [*snmp_community*]
#   The SNMP community to use to poll the device. Optional
#
# [*interfaces*]
#   Whether to perform interface status checks. Defaults to false.
#
# [*bgp*]
#   Whether to perform BGP checks. Defaults to false.
#
# === Examples
#
#  netops::check { 'cr1-esams':
#      ipv4 => '91.198.174.245',
#      bgp  => true,
#  }

define netops::check(
    $ipv4,
    $ipv6=undef,
    $snmp_community=undef,
    $bgp=false,
    $interfaces=false,
) {

    @monitoring::host { $title:
        ip_address => $ipv4,
        group      => 'routers',
    }

    if $ipv6 {
        @monitoring::host { "${title} IPv6":
            ip_address => $ipv6,
            group      => 'routers',
        }
    }

    if $interfaces {
        @monitoring::service { "${title} interfaces":
            host          => $title,
            group         => 'routers',
            description   => 'Router interfaces',
            check_command => "check_ifstatus_nomon!${snmp_community}",
        }
    }

    if $bgp {
        @monitoring::service { "${title} BGP status":
            host          => $title,
            group         => 'routers',
            description   => 'BGP status',
            check_command => "check_bgp!${snmp_community}",
        }
    }
}
