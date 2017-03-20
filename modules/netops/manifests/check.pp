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
# [*alarms*]
#   Whether to perform chassis alarms checks. Defaults to false.
#
# [*interfaces*]
#   Whether to perform interface status checks. Defaults to false.
#
# [*bgp*]
#   Whether to perform BGP checks. Defaults to false.
#
# [*parents*]
#   The parent devices of this device. Accepts either an array or a comma
#   separate string. Defaults to undef
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
    $group='routers',
    $alarms=false,
    $bgp=false,
    $interfaces=false,
    $parents=undef,
) {

    # If we get an array convert it to a comma separated string
    if $parents and is_array($parents) {
        $real_parents = join($parents, ',')
    # Otherwise, pass it as is (undef or string)
    } else {
        $real_parents = $parents
    }

    @monitoring::host { $title:
        ip_address => $ipv4,
        group      => $group,
        parents    => $real_parents,
    }

    if $ipv6 {
        @monitoring::host { "${title} IPv6":
            ip_address => $ipv6,
            group      => $group,
        }
    }

    if $alarms {
        @monitoring::service { "${title} Juniper alarms":
            host          => $title,
            group         => $group,
            description   => 'Juniper alarms',
            check_command => "check_jnx_alarms!${snmp_community}",
        }
    }

    if $interfaces {
        @monitoring::service { "${title} interfaces":
            host          => $title,
            group         => $group,
            description   => 'Router interfaces',
            check_command => "check_ifstatus_nomon!${snmp_community}",
        }
    }

    if $bgp {
        @monitoring::service { "${title} BGP status":
            host          => $title,
            group         => $group,
            description   => 'BGP status',
            check_command => "check_bgp!${snmp_community}",
        }
    }
}
